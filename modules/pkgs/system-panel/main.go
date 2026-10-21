// system-panel: loopback panel for Home Manager user services.
// It shows live systemd state and starts or stops those units. It never
// reads secret files.
package main

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
)

//go:embed web
var webFS embed.FS

var unitNameRe = regexp.MustCompile(`^[a-zA-Z0-9_.@:-]+\.service$`)

// systemAllow is the only system-wide unit this panel may touch.
var systemAllow = map[string]bool{"greetd.service": true}

var noisePrefixes = []string{
	"dbus", "pipewire", "wireplumber", "xdg-", "gnome", "at-spi", "gvfs",
	"dconf", "filter-chain", "pk-debconf", "rtkit", "systemd-",
}

type Config struct {
	Listen string `json:"listen"`
}

func defaultConfig() Config { return Config{Listen: "127.0.0.1:7879"} }

func loopbackAddr(addr string) error {
	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		return fmt.Errorf("listen: %v", err)
	}
	if ip := net.ParseIP(host); host != "localhost" && (ip == nil || !ip.IsLoopback()) {
		return fmt.Errorf("listen: %q is not loopback", addr)
	}
	return nil
}

func (c Config) validate() error { return loopbackAddr(c.Listen) }

type Unit struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Active      string `json:"active"`
	Sub         string `json:"sub"`
	Enabled     string `json:"enabled"`
	Scope       string `json:"scope"`
	Group       string `json:"group"`
	Switchable  bool   `json:"switchable"`
}

type Group struct {
	ID    string `json:"id"`
	Label string `json:"label"`
	Units []Unit `json:"units"`
}

type Result struct {
	OK  bool   `json:"ok"`
	Msg string `json:"msg"`
}

func groupOf(name string) string {
	n := strings.TrimSuffix(name, ".service")
	switch {
	case n == "greetd":
		return "session"
	case strings.Contains(n, "agenix") || n == "gpg-agent" || n == "ssh-agent" || strings.Contains(n, "keyd"):
		return "secrets"
	case strings.Contains(n, "cloudflared") || strings.Contains(n, "tunnel"):
		return "tunnels"
	case strings.Contains(n, "orca") || strings.Contains(n, "omp") || strings.Contains(n, "herdr") ||
		strings.Contains(n, "collie") || strings.Contains(n, "jev") || strings.Contains(n, "magpie") ||
		strings.Contains(n, "cursor"):
		return "agents"
	default:
		return "other"
	}
}

func noisy(name string) bool {
	base := strings.TrimSuffix(name, ".service")
	for _, p := range noisePrefixes {
		if base == p || strings.HasPrefix(base, p) {
			return true
		}
	}
	return false
}

func managed(fragment string) bool {
	f := strings.ToLower(fragment)
	return strings.Contains(f, "home-manager") ||
		strings.Contains(f, ".config/systemd/user") ||
		strings.Contains(f, "/nix/store/")
}

func keep(u Unit, fragment string) bool {
	if u.Scope == "system" {
		return systemAllow[u.Name]
	}
	if noisy(u.Name) {
		return false
	}
	if groupOf(u.Name) != "other" {
		return true
	}
	return managed(fragment)
}

func parseShow(out, scope string) []Unit {
	var units []Unit
	for _, block := range strings.Split(out, "\n\n") {
		props := map[string]string{}
		for _, line := range strings.Split(block, "\n") {
			k, v, ok := strings.Cut(line, "=")
			if ok {
				props[k] = v
			}
		}
		name := props["Id"]
		if name == "" || !unitNameRe.MatchString(name) {
			continue
		}
		u := Unit{
			Name:        name,
			Description: props["Description"],
			Active:      props["ActiveState"],
			Sub:         props["SubState"],
			Enabled:     props["UnitFileState"],
			Scope:       scope,
			Group:       groupOf(name),
			Switchable:  scope == "user" || systemAllow[name],
		}
		if !keep(u, props["FragmentPath"]) {
			continue
		}
		if u.Name == "system-panel.service" {
			u.Switchable = true
		}
		units = append(units, u)
	}
	return units
}

var groupOrder = []Group{
	{ID: "session", Label: "会话 greetd"},
	{ID: "secrets", Label: "密钥 agenix"},
	{ID: "agents", Label: "Orca / 代理"},
	{ID: "tunnels", Label: "Cloudflare 隧道"},
	{ID: "other", Label: "其它用户服务"},
}

func assemble(units []Unit) []Group {
	by := map[string][]Unit{}
	for _, u := range units {
		by[u.Group] = append(by[u.Group], u)
	}
	out := make([]Group, 0, len(groupOrder))
	for _, g := range groupOrder {
		us := by[g.ID]
		sort.Slice(us, func(i, j int) bool { return us[i].Name < us[j].Name })
		g.Units = us
		out = append(out, g)
	}
	return out
}

type App struct {
	path string
	mu   sync.RWMutex
	cfg  Config
	act  sync.Mutex
}

func (a *App) config() Config {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return a.cfg
}

func expand(p string) string {
	if strings.HasPrefix(p, "~/") {
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, p[2:])
		}
	}
	return p
}

func (a *App) load() error {
	cfg := defaultConfig()
	data, err := os.ReadFile(a.path)
	switch {
	case errors.Is(err, fs.ErrNotExist):
	case err != nil:
		return err
	default:
		if err := json.Unmarshal(data, &cfg); err != nil {
			return fmt.Errorf("%s: %v", a.path, err)
		}
	}
	if err := cfg.validate(); err != nil {
		return err
	}
	a.cfg = cfg
	return nil
}
func run(ctx context.Context, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, args[0], args[1:]...)
	out, err := cmd.CombinedOutput()
	text := strings.TrimSpace(string(out))
	if err != nil {
		if text == "" {
			text = err.Error()
		}
		return text, err
	}
	return text, nil
}


func (a *App) status(ctx context.Context) []Group {
	var units []Unit
	list, err := run(ctx, "systemctl", "--user", "list-unit-files", "--type=service", "--no-legend", "--plain", "--no-pager")
	if err != nil && list == "" {
		log.Printf("user units: %v", err)
	}
	var names []string
	for _, line := range strings.Split(list, "\n") {
		fields := strings.Fields(line)
		if len(fields) > 0 && strings.HasSuffix(fields[0], ".service") {
			names = append(names, fields[0])
		}
	}
	if len(names) > 0 {
		args := []string{"systemctl", "--user", "show", "--no-pager",
			"-p", "Id", "-p", "Description", "-p", "ActiveState", "-p", "SubState", "-p", "UnitFileState", "-p", "FragmentPath"}
		args = append(args, names...)
		out, err := run(ctx, args...)
		if err != nil && out == "" {
			log.Printf("user show: %v", err)
		}
		units = append(units, parseShow(out, "user")...)
	}
	sys, err := run(ctx, "systemctl", "show", "greetd.service", "--no-pager",
		"-p", "Id", "-p", "Description", "-p", "ActiveState", "-p", "SubState", "-p", "UnitFileState", "-p", "FragmentPath")
	if err == nil || strings.Contains(sys, "Id=") {
		units = append(units, parseShow(sys, "system")...)
	}
	return assemble(units)
}

func (a *App) switchUnit(ctx context.Context, name, op string) Result {
	if !unitNameRe.MatchString(name) {
		return Result{Msg: "非法单元名"}
	}
	switch op {
	case "start", "stop", "restart":
	default:
		return Result{Msg: "动作必须是 start|stop|restart"}
	}
	if name == "system-panel.service" && op == "stop" {
		return Result{Msg: "不能从面板自己停掉 system-panel"}
	}
	args := []string{"systemctl"}
	if systemAllow[name] {
		args = []string{"sudo", "-n", "systemctl"}
	} else {
		// Re-check it is a user unit we would display, so a crafted name
		// cannot target an arbitrary system unit.
		shown := false
		for _, g := range a.status(ctx) {
			for _, u := range g.Units {
				if u.Name == name && u.Scope == "user" && u.Switchable {
					shown = true
				}
			}
		}
		if !shown {
			return Result{Msg: "只能切换面板列出的用户服务"}
		}
		args = append(args, "--user")
	}
	args = append(args, op, name)
	text, err := run(ctx, args...)
	if err != nil {
		return Result{Msg: text}
	}
	if text == "" {
		text = op + " " + name
	}
	return Result{OK: true, Msg: text}
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

func guard(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		host := r.Host
		if h, _, err := net.SplitHostPort(host); err == nil {
			host = h
		}
		if ip := net.ParseIP(strings.Trim(host, "[]")); host != "localhost" && (ip == nil || !ip.IsLoopback()) {
			http.Error(w, "forbidden host", http.StatusForbidden)
			return
		}
		if r.Method != http.MethodGet && r.Header.Get("X-System-Panel") != "1" {
			http.Error(w, "missing X-System-Panel header", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (a *App) routes() http.Handler {
	mux := http.NewServeMux()
	sub, _ := fs.Sub(webFS, "web")
	mux.Handle("GET /", http.FileServer(http.FS(sub)))
	mux.HandleFunc("GET /api/status", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 8*time.Second)
		defer cancel()
		writeJSON(w, 200, map[string]any{"groups": a.status(ctx)})
	})
	mux.HandleFunc("POST /api/unit/{name}/{op}", func(w http.ResponseWriter, r *http.Request) {
		if !a.act.TryLock() {
			writeJSON(w, 409, Result{Msg: "另一个操作正在进行"})
			return
		}
		defer a.act.Unlock()
		ctx, cancel := context.WithTimeout(r.Context(), 25*time.Second)
		defer cancel()
		res := a.switchUnit(ctx, r.PathValue("name"), r.PathValue("op"))
		log.Printf("unit %s %s ok=%v %s", r.PathValue("name"), r.PathValue("op"), res.OK, res.Msg)
		code := 200
		if !res.OK {
			code = 500
		}
		writeJSON(w, code, res)
	})
	return guard(mux)
}

func main() {
	def := "~/.config/system-panel/config.json"
	if x := os.Getenv("XDG_CONFIG_HOME"); x != "" {
		def = filepath.Join(x, "system-panel", "config.json")
	}
	cfgPath := flag.String("config", def, "JSON config path")
	listen := flag.String("listen", "", "override listen address (loopback only)")
	printCfg := flag.Bool("print-config", false, "print effective config and exit")
	flag.Parse()

	a := &App{path: expand(*cfgPath)}
	if err := a.load(); err != nil {
		log.Fatal(err)
	}
	if *printCfg {
		data, _ := json.MarshalIndent(a.config(), "", "  ")
		fmt.Println(string(data))
		return
	}
	addr := a.config().Listen
	if *listen != "" {
		addr = *listen
	}
	if err := loopbackAddr(addr); err != nil {
		log.Fatal(err)
	}
	srv := &http.Server{Addr: addr, Handler: a.routes(), ReadHeaderTimeout: 5 * time.Second}
	log.Printf("system-panel on http://%s", addr)
	log.Fatal(srv.ListenAndServe())
}
