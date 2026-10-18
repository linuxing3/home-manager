// net-panel: loopback-only control panel for Vivo USB share / hotspot,
// Isvoro HK WireGuard and the 1080/18080 reverse proxies.
package main

import (
	"bytes"
	"context"
	"embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

//go:embed web
var webFS embed.FS

type LANConfig struct {
	Iface   string `json:"iface"`
	Gateway string `json:"gateway"`
}

type VivoConfig struct {
	Service   string `json:"service"`
	OffFlag   string `json:"off_flag"`
	AdbSerial string `json:"adb_serial"`
	PhoneTun  string `json:"phone_tun_ip"`
	RelayPort int    `json:"relay_port"`
}

type HotspotConfig struct {
	SSID      string `json:"ssid"`
	Security  string `json:"security"`
	PassFile  string `json:"pass_file"`
	GatewayIP string `json:"gateway_ip"`
}

type WGConfig struct {
	Iface    string `json:"iface"`
	UpCmd    string `json:"up_cmd"`
	DownCmd  string `json:"down_cmd"`
	Endpoint string `json:"endpoint"`
	Address  string `json:"address"`
}

type ProxyEntry struct {
	Listen string `json:"listen"`
	Port   int    `json:"port"`
}

type ProxyConfig struct {
	Socks      ProxyEntry `json:"socks"`
	HTTP       ProxyEntry `json:"http"`
	AdbReverse bool       `json:"adb_reverse"`
}

type Config struct {
	Listen    string        `json:"listen"`
	LAN       LANConfig     `json:"lan"`
	Vivo      VivoConfig    `json:"vivo"`
	Hotspot   HotspotConfig `json:"hotspot"`
	WireGuard WGConfig      `json:"wireguard"`
	Proxy     ProxyConfig   `json:"proxy"`
}

func defaultConfig() Config {
	return Config{
		Listen: "127.0.0.1:7878",
		LAN:    LANConfig{Iface: "enp11s0", Gateway: "10.10.30.1"},
		Vivo: VivoConfig{
			Service:   "gnirehtet-share",
			OffFlag:   "~/.local/state/vivo-off",
			PhoneTun:  "10.0.0.2",
			RelayPort: 31416,
		},
		Hotspot: HotspotConfig{
			SSID:      "feifei",
			Security:  "wpa2",
			PassFile:  "~/.config/net-panel/hotspot.pass",
			GatewayIP: "10.21.163.227",
		},
		WireGuard: WGConfig{
			Iface:    "wg0",
			UpCmd:    "isvoro-wg-up",
			DownCmd:  "isvoro-wg-down",
			Endpoint: "103.138.72.79:10010",
			Address:  "10.66.66.2/24",
		},
		Proxy: ProxyConfig{
			Socks:      ProxyEntry{Listen: "127.0.0.1", Port: 1080},
			HTTP:       ProxyEntry{Listen: "127.0.0.1", Port: 18080},
			AdbReverse: true,
		},
	}
}

var ifaceRe = regexp.MustCompile(`^[A-Za-z0-9_.:-]{1,15}$`)
var ssidRe = regexp.MustCompile(`^[^'\x00-\x1f]{1,32}$`)

func (c *Config) validate() error {
	if err := loopbackAddr(c.Listen); err != nil {
		return err
	}
	for name, v := range map[string]string{"lan.iface": c.LAN.Iface, "wireguard.iface": c.WireGuard.Iface} {
		if !ifaceRe.MatchString(v) {
			return fmt.Errorf("%s: invalid interface name %q", name, v)
		}
	}
	for name, v := range map[string]string{
		"lan.gateway": c.LAN.Gateway, "hotspot.gateway_ip": c.Hotspot.GatewayIP,
		"vivo.phone_tun_ip": c.Vivo.PhoneTun, "proxy.socks.listen": c.Proxy.Socks.Listen,
		"proxy.http.listen": c.Proxy.HTTP.Listen,
	} {
		if net.ParseIP(v) == nil {
			return fmt.Errorf("%s: invalid IP %q", name, v)
		}
	}
	for name, p := range map[string]int{
		"proxy.socks.port": c.Proxy.Socks.Port, "proxy.http.port": c.Proxy.HTTP.Port, "vivo.relay_port": c.Vivo.RelayPort,
	} {
		if p < 1 || p > 65535 {
			return fmt.Errorf("%s: port out of range", name)
		}
	}
	if c.Proxy.Socks.Port == c.Proxy.HTTP.Port {
		return errors.New("proxy ports must differ")
	}
	if _, _, err := net.SplitHostPort(c.WireGuard.Endpoint); err != nil {
		return fmt.Errorf("wireguard.endpoint: %v", err)
	}
	if _, _, err := net.ParseCIDR(c.WireGuard.Address); err != nil {
		return fmt.Errorf("wireguard.address: %v", err)
	}
	if !ssidRe.MatchString(c.Hotspot.SSID) {
		return errors.New("hotspot.ssid: 1-32 chars, no single quote or control chars")
	}
	switch c.Hotspot.Security {
	case "open", "wpa2", "wpa3", "wpa3_transition":
	default:
		return errors.New("hotspot.security: open|wpa2|wpa3|wpa3_transition")
	}
	if strings.TrimSpace(c.WireGuard.UpCmd) == "" || strings.TrimSpace(c.WireGuard.DownCmd) == "" || c.Vivo.Service == "" {
		return errors.New("wireguard up/down commands and vivo.service are required")
	}
	return nil
}

func loopbackAddr(addr string) error {
	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		return fmt.Errorf("listen: %v", err)
	}
	if ip := net.ParseIP(host); host != "localhost" && (ip == nil || !ip.IsLoopback()) {
		return fmt.Errorf("listen: %q is not loopback; net-panel only binds 127.0.0.1/::1", addr)
	}
	return nil
}

func expand(p string) string {
	if strings.HasPrefix(p, "~/") {
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, p[2:])
		}
	}
	return p
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
		return fmt.Errorf("%s: %v", a.path, err)
	}
	a.cfg = cfg
	return nil
}

func (a *App) save(cfg Config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(a.path), 0o700); err != nil {
		return err
	}
	tmp := a.path + ".tmp"
	if err := os.WriteFile(tmp, append(data, '\n'), 0o600); err != nil {
		return err
	}
	if err := os.Rename(tmp, a.path); err != nil {
		return err
	}
	a.mu.Lock()
	a.cfg = cfg
	a.mu.Unlock()
	return nil
}

// ---------- command execution ----------

var secretLine = regexp.MustCompile(`(?i)private|preshared`)

// run executes without a controlling terminal so sudo fails fast instead of
// prompting; output lines that look key-related are dropped.
func run(timeout time.Duration, stdin string, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	if stdin != "" {
		cmd.Stdin = strings.NewReader(stdin)
	}
	var buf bytes.Buffer
	cmd.Stdout = &buf
	cmd.Stderr = &buf
	err := cmd.Run()
	if ctx.Err() != nil {
		err = fmt.Errorf("%s: timeout after %s", name, timeout)
	}
	return redact(buf.String()), err
}

func redact(s string) string {
	lines := strings.Split(strings.TrimRight(strings.ReplaceAll(s, "\r", ""), "\n"), "\n")
	out := lines[:0]
	for _, l := range lines {
		if secretLine.MatchString(l) {
			continue
		}
		out = append(out, l)
	}
	s = strings.Join(out, "\n")
	if len(s) > 8000 {
		s = s[len(s)-8000:]
	}
	return s
}

func (a *App) adb(cfg Config, timeout time.Duration, stdin string, args ...string) (string, error) {
	if cfg.Vivo.AdbSerial != "" {
		args = append([]string{"-s", cfg.Vivo.AdbSerial}, args...)
	}
	return run(timeout, stdin, "adb", args...)
}

func (a *App) adbDevice(cfg Config) bool {
	out, err := a.adb(cfg, 3*time.Second, "", "get-state")
	return err == nil && strings.TrimSpace(out) == "device"
}

func userctl(args ...string) (string, error) {
	return run(20*time.Second, "", "systemctl", append([]string{"--user"}, args...)...)
}

func unitActive(unit string) bool {
	_, err := userctl("is-active", "--quiet", unit)
	return err == nil
}

// ---------- status ----------

type Listener struct {
	Addr  string `json:"addr"`
	Proc  string `json:"proc"`
	PID   int    `json:"pid"`
	Owner string `json:"owner"`
}

var ssUsers = regexp.MustCompile(`users:\(\("([^"]+)",pid=(\d+)`)

func listeners() map[int][]Listener {
	out, _ := run(5*time.Second, "", "ss", "-ltnpH")
	res := map[int][]Listener{}
	for _, line := range strings.Split(out, "\n") {
		f := strings.Fields(line)
		if len(f) < 4 {
			continue
		}
		local := f[3]
		i := strings.LastIndexByte(local, ':')
		if i < 0 {
			continue
		}
		port, err := strconv.Atoi(local[i+1:])
		if err != nil {
			continue
		}
		l := Listener{Addr: local}
		if m := ssUsers.FindStringSubmatch(line); m != nil {
			l.Proc = m[1]
			l.PID, _ = strconv.Atoi(m[2])
			l.Owner = unitOf(l.PID)
		}
		res[port] = append(res[port], l)
	}
	return res
}

func unitOf(pid int) string {
	data, err := os.ReadFile(fmt.Sprintf("/proc/%d/cgroup", pid))
	if err != nil {
		return ""
	}
	for _, seg := range strings.Split(strings.TrimSpace(string(data)), "/") {
		if strings.HasSuffix(seg, ".service") && !strings.HasPrefix(seg, "user@") {
			return strings.TrimSuffix(seg, ".service")
		}
	}
	return ""
}

type IfAddr struct {
	Name string `json:"name"`
	IP   string `json:"ip"`
}

type VivoStatus struct {
	AdbState      string   `json:"adb_state"`
	Model         string   `json:"model"`
	Android       string   `json:"android"`
	ServiceActive bool     `json:"service_active"`
	OffFlag       bool     `json:"off_flag"`
	Watchdog      bool     `json:"watchdog_timer"`
	Relay         bool     `json:"relay_listening"`
	TunIP         string   `json:"tun_ip"`
	Reverse       []string `json:"adb_reverse"`
	Hotspot       bool     `json:"hotspot_active"`
	HotspotIfs    []IfAddr `json:"hotspot_ifaces"`
	StaIface      string   `json:"sta_iface"`
}

type WGStatus struct {
	Up        bool     `json:"up"`
	Addrs     []string `json:"addrs"`
	MTU       int      `json:"mtu"`
	RxBytes   int64    `json:"rx_bytes"`
	TxBytes   int64    `json:"tx_bytes"`
	DefaultWG bool     `json:"default_via_wg"`
	Routes    []string `json:"routes"`
	Endpoint  string   `json:"endpoint"`
	Handshake string   `json:"latest_handshake"`
	Transfer  string   `json:"transfer"`
	PeerKey   string   `json:"peer_public_key"`
	WgNote    string   `json:"wg_note"`
}

type ProxyStatus struct {
	Port      int        `json:"port"`
	Listening []Listener `json:"listening"`
	Unit      string     `json:"unit"`
	UnitOn    bool       `json:"unit_active"`
	Reverse   bool       `json:"adb_reverse"`
}

type Status struct {
	Time     string                 `json:"time"`
	RouteGet string                 `json:"route_get"`
	Default  string                 `json:"default_route"`
	Rules    []string               `json:"ip_rules"`
	LANAddr  []string               `json:"lan_addrs"`
	Vivo     VivoStatus             `json:"vivo"`
	WG       WGStatus               `json:"wireguard"`
	Proxies  map[string]ProxyStatus `json:"proxies"`
}

func lines(s string) []string {
	var out []string
	for _, l := range strings.Split(s, "\n") {
		if l = strings.TrimSpace(l); l != "" {
			out = append(out, l)
		}
	}
	return out
}

func ifaceAddrs(name string) []string {
	ifc, err := net.InterfaceByName(name)
	if err != nil {
		return nil
	}
	addrs, _ := ifc.Addrs()
	out := make([]string, 0, len(addrs))
	for _, ad := range addrs {
		out = append(out, ad.String())
	}
	return out
}

func readInt(path string) int64 {
	data, _ := os.ReadFile(path)
	n, _ := strconv.ParseInt(strings.TrimSpace(string(data)), 10, 64)
	return n
}

func (a *App) vivoStatus(cfg Config, ls map[int][]Listener) VivoStatus {
	st := VivoStatus{
		ServiceActive: unitActive(cfg.Vivo.Service),
		Watchdog:      unitActive("vivo-watchdog.timer"),
		Relay:         len(ls[cfg.Vivo.RelayPort]) > 0,
	}
	_, err := os.Stat(expand(cfg.Vivo.OffFlag))
	st.OffFlag = err == nil
	state, err := a.adb(cfg, 3*time.Second, "", "get-state")
	if err != nil {
		st.AdbState = "absent"
		return st
	}
	st.AdbState = strings.TrimSpace(state)
	if st.AdbState != "device" {
		return st
	}
	out, _ := a.adb(cfg, 5*time.Second, "",
		"shell", "getprop ro.product.model; getprop ro.build.version.release; getprop wifi.interface; echo ---; ip -4 -o addr show")
	parts := strings.SplitN(out, "---", 2)
	head := lines(parts[0])
	if len(head) > 0 {
		st.Model = head[0]
	}
	if len(head) > 1 {
		st.Android = head[1]
	}
	st.StaIface = "wlan0"
	if len(head) > 2 && head[2] != "" {
		st.StaIface = head[2]
	}
	if len(parts) == 2 {
		for _, l := range lines(parts[1]) {
			f := strings.Fields(l)
			if len(f) < 4 || f[2] != "inet" {
				continue
			}
			name, ip := f[1], strings.SplitN(f[3], "/", 2)[0]
			switch {
			case name == "tun0":
				st.TunIP = ip
			case name != st.StaIface && (strings.HasPrefix(name, "wlan") || strings.HasPrefix(name, "ap") || strings.HasPrefix(name, "swlan")):
				st.HotspotIfs = append(st.HotspotIfs, IfAddr{Name: name, IP: ip})
			}
		}
	}
	st.Hotspot = len(st.HotspotIfs) > 0
	rev, _ := a.adb(cfg, 3*time.Second, "", "reverse", "--list")
	st.Reverse = lines(rev)
	return st
}

var wgField = regexp.MustCompile(`^\S+\s+(.*)$`)

func (a *App) wgStatus(cfg Config) WGStatus {
	ifn := cfg.WireGuard.Iface
	st := WGStatus{}
	ifc, err := net.InterfaceByName(ifn)
	if err != nil {
		return st
	}
	st.Up = ifc.Flags&net.FlagUp != 0
	st.MTU = ifc.MTU
	st.Addrs = ifaceAddrs(ifn)
	st.RxBytes = readInt("/sys/class/net/" + ifn + "/statistics/rx_bytes")
	st.TxBytes = readInt("/sys/class/net/" + ifn + "/statistics/tx_bytes")
	r, _ := run(3*time.Second, "", "ip", "route", "show", "table", "all", "dev", ifn)
	st.Routes = lines(r)
	if ep, _, err := net.SplitHostPort(cfg.WireGuard.Endpoint); err == nil {
		if pin, _ := run(3*time.Second, "", "ip", "route", "show", ep+"/32"); strings.TrimSpace(pin) != "" {
			st.Routes = append(st.Routes, "pin: "+ep+" "+strings.TrimSpace(pin))
		}
	}
	// `wg show` needs root; query only non-secret fields, never `dump`.
	q := func(field string) (string, bool) {
		out, err := run(4*time.Second, "", "sudo", "-n", "wg", "show", ifn, field)
		if err != nil {
			return "", false
		}
		if m := wgField.FindStringSubmatch(strings.TrimSpace(strings.SplitN(out, "\n", 2)[0])); m != nil {
			st.PeerKey = strings.Fields(out)[0]
			return m[1], true
		}
		return "", true
	}
	if ep, ok := q("endpoints"); ok {
		st.Endpoint = ep
		if hs, _ := q("latest-handshakes"); hs != "" {
			if ts, err := strconv.ParseInt(hs, 10, 64); err == nil && ts > 0 {
				st.Handshake = fmt.Sprintf("%s ago", time.Since(time.Unix(ts, 0)).Round(time.Second))
			} else {
				st.Handshake = "never"
			}
		}
		if tr, _ := q("transfer"); tr != "" {
			if f := strings.Fields(tr); len(f) == 2 {
				st.Transfer = "rx " + f[0] + " B / tx " + f[1] + " B"
			}
		}
	} else {
		st.WgNote = "handshake/endpoint need passwordless sudo for `wg show`"
	}
	return st
}

func (a *App) status() Status {
	cfg := a.config()
	var st Status
	st.Time = time.Now().Format(time.RFC3339)
	ls := listeners()
	var wg sync.WaitGroup
	wg.Add(2)
	go func() { defer wg.Done(); st.Vivo = a.vivoStatus(cfg, ls) }()
	go func() { defer wg.Done(); st.WG = a.wgStatus(cfg) }()
	rg, _ := run(3*time.Second, "", "ip", "route", "get", "1.1.1.1")
	st.RouteGet = strings.TrimSpace(strings.SplitN(rg, "\n", 2)[0])
	dr, _ := run(3*time.Second, "", "ip", "route", "show", "default")
	st.Default = strings.Join(lines(dr), " | ")
	rules, _ := run(3*time.Second, "", "ip", "rule")
	st.Rules = lines(rules)
	st.LANAddr = ifaceAddrs(cfg.LAN.Iface)
	wg.Wait()
	st.WG.DefaultWG = st.WG.Up && strings.Contains(st.RouteGet, " dev "+cfg.WireGuard.Iface+" ")
	st.Proxies = map[string]ProxyStatus{}
	for _, kind := range []string{"socks", "http"} {
		pe := proxyEntry(cfg, kind)
		ps := ProxyStatus{Port: pe.Port, Listening: ls[pe.Port], Unit: proxyUnit(kind)}
		ps.UnitOn = unitActive(ps.Unit)
		for _, r := range st.Vivo.Reverse {
			if strings.Contains(r, fmt.Sprintf("tcp:%d tcp:%d", pe.Port, pe.Port)) {
				ps.Reverse = true
			}
		}
		st.Proxies[kind] = ps
	}
	return st
}

// ---------- actions ----------

func proxyEntry(cfg Config, kind string) ProxyEntry {
	if kind == "socks" {
		return cfg.Proxy.Socks
	}
	return cfg.Proxy.HTTP
}

func proxyUnit(kind string) string { return "net-panel-" + kind }

type Result struct {
	OK     bool   `json:"ok"`
	Msg    string `json:"msg"`
	Output string `json:"output,omitempty"`
}

func fail(msg string, out string, err error) Result {
	if err != nil {
		msg += ": " + err.Error()
	}
	return Result{Msg: msg, Output: out}
}

func (a *App) vivo(on bool) Result {
	cfg := a.config()
	flagPath := expand(cfg.Vivo.OffFlag)
	if !on {
		if err := os.MkdirAll(filepath.Dir(flagPath), 0o755); err != nil {
			return fail("create off flag dir", "", err)
		}
		if err := os.WriteFile(flagPath, nil, 0o644); err != nil {
			return fail("create off flag", "", err)
		}
		out, err := userctl("stop", cfg.Vivo.Service)
		if err != nil {
			return fail("systemctl --user stop "+cfg.Vivo.Service, out, err)
		}
		return Result{OK: true, Msg: "USB 共享已停止；vivo-off 标记已写入，watchdog 不会自动重启"}
	}
	if err := os.Remove(flagPath); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return fail("remove off flag", "", err)
	}
	if !a.adbDevice(cfg) {
		return Result{OK: true, Msg: "已清除 vivo-off 标记；未检测到 adb device，插上 VIVO 后 watchdog 会在 30s 内启动共享"}
	}
	out, err := userctl("start", cfg.Vivo.Service)
	if err != nil {
		return fail("systemctl --user start "+cfg.Vivo.Service, out, err)
	}
	return Result{OK: true, Msg: "USB 共享已启动 (" + cfg.Vivo.Service + ")；手机上需允许 VPN 连接"}
}

func shq(s string) string { return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'" }

func (a *App) hotspot(on bool) Result {
	cfg := a.config()
	if !a.adbDevice(cfg) {
		return Result{Msg: "未检测到 adb device（VIVO 未通过 USB 连接或未授权）"}
	}
	openSettings := func(prefix string, out string) Result {
		o2, err := a.adb(cfg, 8*time.Second, "", "shell", "am start -n com.android.settings/.TetherSettings")
		if err != nil {
			return fail(prefix+"；打开热点设置页也失败", out+"\n"+o2, err)
		}
		return Result{OK: true, Msg: prefix + "；已在手机上打开「热点与网络共享」设置页，请手动切换", Output: out}
	}
	if !on {
		out, err := a.adb(cfg, 10*time.Second, "", "shell", "cmd wifi stop-softap")
		if err != nil || strings.Contains(strings.ToLower(out), "exception") {
			return openSettings("cmd wifi stop-softap 不可用", out)
		}
		return Result{OK: true, Msg: "已请求关闭热点", Output: out}
	}
	var pass string
	if cfg.Hotspot.Security != "open" {
		data, err := os.ReadFile(expand(cfg.Hotspot.PassFile))
		if err != nil {
			return openSettings("未找到热点密码文件 "+cfg.Hotspot.PassFile, "")
		}
		pass = strings.TrimSpace(string(data))
	}
	// Passphrase goes over stdin so it never appears in host argv or logs.
	script := "read -r p; cmd wifi start-softap " + shq(cfg.Hotspot.SSID) + " " + cfg.Hotspot.Security + ` "$p"`
	if cfg.Hotspot.Security == "open" {
		script = "cmd wifi start-softap " + shq(cfg.Hotspot.SSID) + " open"
	}
	out, err := a.adb(cfg, 15*time.Second, pass+"\n", "shell", script)
	if pass != "" {
		out = strings.ReplaceAll(out, pass, "***")
	}
	if err != nil || strings.Contains(strings.ToLower(out), "exception") || strings.Contains(strings.ToLower(out), "unknown command") {
		return openSettings("cmd wifi start-softap 失败（需 Android 11+ 且 shell 有 NETWORK_SETTINGS 权限）", out)
	}
	return Result{OK: true, Msg: "已请求开启热点 " + cfg.Hotspot.SSID, Output: out}
}

func (a *App) wireguard(on bool) Result {
	cfg := a.config()
	line := cfg.WireGuard.DownCmd
	if on {
		line = cfg.WireGuard.UpCmd
	}
	argv := strings.Fields(expand(line))
	out, err := run(90*time.Second, "", argv[0], argv[1:]...)
	if err != nil {
		msg := line + " 失败"
		if strings.Contains(out, "a terminal is required") || strings.Contains(out, "password is required") {
			msg += "（sudo 需要密码：请主公在终端运行一次 sudo -v，或配置该命令免密）"
		}
		return fail(msg, out, err)
	}
	return Result{OK: true, Msg: line + " 完成", Output: out}
}

func (a *App) proxy(kind string, on bool) Result {
	cfg := a.config()
	pe := proxyEntry(cfg, kind)
	unit := proxyUnit(kind)
	port := strconv.Itoa(pe.Port)
	device := cfg.Proxy.AdbReverse && a.adbDevice(cfg)
	if !on {
		var notes []string
		if unitActive(unit) {
			if out, err := userctl("stop", unit); err != nil {
				return fail("stop "+unit, out, err)
			}
			notes = append(notes, "已停止 "+unit)
		}
		if ls := listeners()[pe.Port]; len(ls) > 0 {
			if out, err := run(5*time.Second, "", "fuser", "-k", port+"/tcp"); err != nil {
				return fail("fuser -k "+port+"/tcp", out, err)
			}
			notes = append(notes, fmt.Sprintf("已结束占用 %s 的 %s (%s)", port, ls[0].Proc, ls[0].Owner))
		}
		if device {
			_, _ = a.adb(cfg, 3*time.Second, "", "reverse", "--remove", "tcp:"+port)
		}
		if len(notes) == 0 {
			notes = append(notes, port+" 本来就未监听")
		}
		return Result{OK: true, Msg: strings.Join(notes, "；")}
	}
	if ls := listeners()[pe.Port]; len(ls) > 0 {
		msg := fmt.Sprintf("%s 已由 %s (%s) 监听", port, ls[0].Proc, ls[0].Owner)
		if device {
			if out, err := a.adb(cfg, 3*time.Second, "", "reverse", "tcp:"+port, "tcp:"+port); err != nil {
				return fail(msg+"；adb reverse 失败", out, err)
			}
			msg += "；adb reverse 已确保"
		}
		return Result{OK: true, Msg: msg}
	}
	var argv []string
	if kind == "socks" {
		bin, err := exec.LookPath("microsocks")
		if err != nil {
			return fail("microsocks not found", "", err)
		}
		argv = []string{bin, "-i", pe.Listen, "-p", port}
	} else {
		bin, err := exec.LookPath("tinyproxy")
		if err != nil {
			return fail("tinyproxy not found", "", err)
		}
		dir := os.Getenv("XDG_RUNTIME_DIR")
		if dir == "" {
			dir = os.TempDir()
		}
		conf := filepath.Join(dir, "net-panel-tinyproxy.conf")
		body := fmt.Sprintf("Port %d\nListen %s\nTimeout 600\nMaxClients 32\nLogLevel Info\nAllow 127.0.0.1\nAllow ::1\nConnectPort 443\nConnectPort 563\n", pe.Port, pe.Listen)
		if err := os.WriteFile(conf, []byte(body), 0o600); err != nil {
			return fail("write tinyproxy conf", "", err)
		}
		argv = []string{bin, "-d", "-c", conf}
	}
	_, _ = userctl("reset-failed", unit)
	args := append([]string{"--user", "--quiet", "--collect", "--unit=" + unit, "-p", "Restart=on-failure"}, argv...)
	if out, err := run(15*time.Second, "", "systemd-run", args...); err != nil {
		return fail("systemd-run "+unit, out, err)
	}
	msg := fmt.Sprintf("%s 已在 %s:%s 启动 (%s)", strings.ToUpper(kind), pe.Listen, port, unit)
	if device {
		if out, err := a.adb(cfg, 3*time.Second, "", "reverse", "tcp:"+port, "tcp:"+port); err != nil {
			return fail(msg+"；adb reverse 失败", out, err)
		}
		msg += "；adb reverse tcp:" + port + " 已映射到手机"
	} else if cfg.Proxy.AdbReverse {
		msg += "；未检测到 adb device，未做 adb reverse"
	}
	return Result{OK: true, Msg: msg}
}

func exitIP() (map[string]any, error) {
	client := &http.Client{Timeout: 12 * time.Second, Transport: &http.Transport{Proxy: nil}}
	resp, err := client.Get("https://ipinfo.io/json")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var raw map[string]any
	if err := json.NewDecoder(io.LimitReader(resp.Body, 1<<16)).Decode(&raw); err != nil {
		return nil, err
	}
	out := map[string]any{}
	for _, k := range []string{"ip", "city", "region", "country", "org"} {
		out[k] = raw[k]
	}
	return out, nil
}

// ---------- HTTP ----------

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

// guard blocks DNS rebinding (Host must be loopback) and cross-site POSTs
// (custom header forces a CORS preflight that is never granted).
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
		if r.Method != http.MethodGet && r.Header.Get("X-Net-Panel") != "1" {
			http.Error(w, "missing X-Net-Panel header", http.StatusForbidden)
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
		writeJSON(w, 200, a.status())
	})
	mux.HandleFunc("GET /api/config", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{"path": a.path, "config": a.config()})
	})
	mux.HandleFunc("POST /api/config", func(w http.ResponseWriter, r *http.Request) {
		cfg := a.config()
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<16))
		dec.DisallowUnknownFields()
		if err := dec.Decode(&cfg); err != nil {
			writeJSON(w, 400, Result{Msg: err.Error()})
			return
		}
		if err := cfg.validate(); err != nil {
			writeJSON(w, 400, Result{Msg: err.Error()})
			return
		}
		old := a.config().Listen
		if err := a.save(cfg); err != nil {
			writeJSON(w, 500, Result{Msg: err.Error()})
			return
		}
		msg := "已保存 " + a.path
		if old != cfg.Listen {
			msg += "；listen 变更需重启 net-panel 生效"
		}
		writeJSON(w, 200, Result{OK: true, Msg: msg})
	})
	mux.HandleFunc("GET /api/exitip", func(w http.ResponseWriter, r *http.Request) {
		info, err := exitIP()
		if err != nil {
			writeJSON(w, 502, Result{Msg: err.Error()})
			return
		}
		writeJSON(w, 200, info)
	})
	mux.HandleFunc("POST /api/action/{target}/{state}", func(w http.ResponseWriter, r *http.Request) {
		state := r.PathValue("state")
		if state != "on" && state != "off" {
			writeJSON(w, 400, Result{Msg: "state must be on|off"})
			return
		}
		on := state == "on"
		if !a.act.TryLock() {
			writeJSON(w, 409, Result{Msg: "另一个操作正在进行"})
			return
		}
		defer a.act.Unlock()
		var res Result
		switch t := r.PathValue("target"); t {
		case "vivo":
			res = a.vivo(on)
		case "hotspot":
			res = a.hotspot(on)
		case "wireguard":
			res = a.wireguard(on)
		case "socks", "http":
			res = a.proxy(t, on)
		default:
			writeJSON(w, 404, Result{Msg: "unknown target " + t})
			return
		}
		log.Printf("action %s/%s ok=%v %s", r.PathValue("target"), state, res.OK, res.Msg)
		code := 200
		if !res.OK {
			code = 500
		}
		writeJSON(w, code, res)
	})
	return guard(mux)
}

func main() {
	defCfg := "~/.config/net-panel/config.json"
	if x := os.Getenv("XDG_CONFIG_HOME"); x != "" {
		defCfg = filepath.Join(x, "net-panel", "config.json")
	}
	cfgPath := flag.String("config", defCfg, "JSON config path")
	listen := flag.String("listen", "", "override listen address (loopback only)")
	printCfg := flag.Bool("print-config", false, "print effective config and exit")
	flag.Parse()

	a := &App{path: expand(*cfgPath)}
	if err := a.load(); err != nil {
		log.Fatal(err)
	}
	if *printCfg {
		data, _ := json.MarshalIndent(a.cfg, "", "  ")
		fmt.Println(string(data))
		return
	}
	addr := a.cfg.Listen
	if *listen != "" {
		addr = *listen
	}
	if err := loopbackAddr(addr); err != nil {
		log.Fatal(err)
	}
	srv := &http.Server{Addr: addr, Handler: a.routes(), ReadHeaderTimeout: 5 * time.Second}
	log.Printf("net-panel on http://%s (config %s)", addr, a.path)
	log.Fatal(srv.ListenAndServe())
}
