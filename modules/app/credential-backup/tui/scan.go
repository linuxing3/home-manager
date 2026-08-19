package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

type presence int

const (
	presentMissing presence = iota
	presentFile
	presentDir
)

func (p presence) String() string {
	switch p {
	case presentFile:
		return "file"
	case presentDir:
		return "dir"
	default:
		return "missing"
	}
}

type sideInfo struct {
	Path     string
	Presence presence
	Size     int64
	Mode     os.FileMode
	Hash     string
}

type pairStatus string

const (
	statusMatch     pairStatus = "match"
	statusDiff      pairStatus = "diff"
	statusHostOnly  pairStatus = "host-only"
	statusUSBOnly   pairStatus = "usb-only"
	statusBothGone  pairStatus = "absent"
	statusNoUSB     pairStatus = "no-usb"
)

type secretPair struct {
	ID       string
	Label    string
	HostRel  string
	USBRel   string
	HostMode os.FileMode
	USBMode  os.FileMode
	Kind     string
	Host     sideInfo
	USB      sideInfo
	Status   pairStatus
}

type scanResult struct {
	Home          string
	USBMount      string
	IdentityDir   string
	IdentityName  string
	USBReady      bool
	USBMessage    string
	Pairs         []secretPair
	TarArchives   []string
	Match         int
	Diff          int
	HostOnly      int
	USBOnly       int
	ChecksumOK    *bool
	ChecksumNote  string
}

func defaultIdentityName() string {
	if v := strings.TrimSpace(os.Getenv("KEYVAULT_IDENTITY")); v != "" {
		return v
	}
	u, err := user.Current()
	if err != nil || u.Username == "" {
		return "uos-Designers"
	}
	return "uos-" + u.Username
}

func catalog() []secretPair {
	return []secretPair{
		{ID: "ssh-ed25519", Label: "SSH ed25519 private", HostRel: ".ssh/id_ed25519", USBRel: "ssh/id_ed25519", HostMode: 0400, USBMode: 0400, Kind: "file"},
		{ID: "ssh-ed25519-pub", Label: "SSH ed25519 public", HostRel: ".ssh/id_ed25519.pub", USBRel: "ssh/id_ed25519.pub", HostMode: 0644, USBMode: 0644, Kind: "file"},
		{ID: "ssh-rsa", Label: "SSH RSA private", HostRel: ".ssh/id_rsa", USBRel: "ssh/id_rsa", HostMode: 0400, USBMode: 0400, Kind: "file"},
		{ID: "ssh-rsa-pub", Label: "SSH RSA public", HostRel: ".ssh/id_rsa.pub", USBRel: "ssh/id_rsa.pub", HostMode: 0644, USBMode: 0644, Kind: "file"},
		{ID: "ssh-known-hosts", Label: "SSH known_hosts", HostRel: ".ssh/known_hosts", USBRel: "ssh/known_hosts", HostMode: 0600, USBMode: 0600, Kind: "file"},
		{ID: "ssh-authorized", Label: "SSH authorized_keys", HostRel: ".ssh/authorized_keys", USBRel: "ssh/authorized_keys", HostMode: 0600, USBMode: 0600, Kind: "file"},
		{ID: "gpg-public", Label: "GPG public.asc", HostRel: "", USBRel: "gpg/public.asc", HostMode: 0600, USBMode: 0600, Kind: "gpg-asc"},
		{ID: "gpg-master", Label: "GPG master-secret.asc", HostRel: "", USBRel: "gpg/master-secret.asc", HostMode: 0600, USBMode: 0600, Kind: "gpg-asc"},
		{ID: "gpg-subkeys", Label: "GPG subkeys-secret.asc", HostRel: "", USBRel: "gpg/subkeys-secret.asc", HostMode: 0600, USBMode: 0600, Kind: "gpg-asc"},
		{ID: "gpg-ownertrust", Label: "GPG ownertrust.txt", HostRel: "", USBRel: "gpg/ownertrust.txt", HostMode: 0600, USBMode: 0600, Kind: "gpg-asc"},
		{ID: "gpg-host", Label: "Host GnuPG homedir", HostRel: ".gnupg", USBRel: "gpg", HostMode: 0700, USBMode: 0700, Kind: "dir"},
		{ID: "age-readme", Label: "Agenix README", HostRel: "", USBRel: "age/README.txt", HostMode: 0644, USBMode: 0644, Kind: "file"},
		{ID: "age-cloudflared", Label: "cloudflared-office-token.age", HostRel: "", USBRel: "age/cloudflared-office-token.age", HostMode: 0600, USBMode: 0600, Kind: "file"},
		{ID: "checksums", Label: "SHA256SUMS", HostRel: "", USBRel: "checksums/SHA256SUMS", HostMode: 0644, USBMode: 0644, Kind: "file"},
	}
}

func findUSBMount() (string, string) {
	if v := strings.TrimSpace(os.Getenv("KEYVAULT_MOUNT")); v != "" {
		if isUsableMount(v) {
			return v, ""
		}
		return "", "KEYVAULT_MOUNT is set but not a usable directory: " + v
	}
	u, _ := user.Current()
	name := "Designers"
	if u != nil && u.Username != "" {
		name = u.Username
	}
	candidates := []string{
		filepath.Join("/media", name, "KEYVAULT"),
		filepath.Join("/run/media", name, "KEYVAULT"),
		"/mnt/keyvault",
		"/keyvault",
	}
	for _, c := range candidates {
		if isUsableMount(c) {
			return c, ""
		}
	}
	return "", "KEYVAULT USB is not mounted"
}

func isUsableMount(path string) bool {
	info, err := os.Lstat(path)
	if err != nil || !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
		return false
	}
	f, err := os.Open(path)
	if err != nil {
		return false
	}
	_ = f.Close()
	return true
}

func inspect(path string) sideInfo {
	info := sideInfo{Path: path, Presence: presentMissing}
	if path == "" {
		return info
	}
	st, err := os.Lstat(path)
	if err != nil {
		return info
	}
	if st.Mode()&os.ModeSymlink != 0 {
		return info
	}
	info.Size = st.Size()
	info.Mode = st.Mode().Perm()
	if st.IsDir() {
		info.Presence = presentDir
		return info
	}
	if !st.Mode().IsRegular() {
		return info
	}
	info.Presence = presentFile
	sum, err := fileSHA256(path)
	if err == nil {
		info.Hash = sum
	}
	return info
}

func fileSHA256(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func classify(p *secretPair, usbReady bool) {
	if !usbReady {
		p.Status = statusNoUSB
		return
	}
	hostYes := p.Host.Presence != presentMissing
	usbYes := p.USB.Presence != presentMissing
	switch {
	case !hostYes && !usbYes:
		p.Status = statusBothGone
	case hostYes && !usbYes:
		p.Status = statusHostOnly
	case !hostYes && usbYes:
		p.Status = statusUSBOnly
	default:
		if p.Kind == "file" && p.Host.Presence == presentFile && p.USB.Presence == presentFile && p.Host.Hash != "" && p.Host.Hash == p.USB.Hash {
			p.Status = statusMatch
			return
		}
		if p.Kind != "file" && p.Host.Presence == p.USB.Presence {
			p.Status = statusMatch
			return
		}
		p.Status = statusDiff
	}
}

func scanAgeHostCandidates(home, repoRoot string) []string {
	var out []string
	relatives := []string{
		"security/secrets/cloudflared-office-token.age",
	}
	roots := []string{repoRoot, filepath.Join(home, ".config/home-manager"), "/share/data/sources/home-config"}
	seen := map[string]struct{}{}
	for _, root := range roots {
		if root == "" {
			continue
		}
		for _, rel := range relatives {
			p := filepath.Join(root, rel)
			if _, ok := seen[p]; ok {
				continue
			}
			seen[p] = struct{}{}
			if st, err := os.Lstat(p); err == nil && st.Mode().IsRegular() {
				out = append(out, p)
			}
		}
	}
	return out
}

func scanAll() scanResult {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("HOME")
	}
	repoRoot := strings.TrimSpace(os.Getenv("KEYVAULT_REPO"))
	if repoRoot == "" {
		repoRoot = "/share/data/sources/home-config"
	}
	res := scanResult{
		Home:         home,
		IdentityName: defaultIdentityName(),
		Pairs:        catalog(),
	}
	mount, msg := findUSBMount()
	res.USBMount = mount
	res.USBMessage = msg
	res.USBReady = mount != ""
	if res.USBReady {
		res.IdentityDir = filepath.Join(mount, res.IdentityName)
		if st, err := os.Lstat(res.IdentityDir); err != nil || !st.IsDir() {
			res.USBMessage = "mounted, but identity pack missing: " + res.IdentityName
		}
	}

	ageHost := ""
	if cands := scanAgeHostCandidates(home, repoRoot); len(cands) > 0 {
		ageHost = cands[0]
	}

	for i := range res.Pairs {
		p := &res.Pairs[i]
		switch p.ID {
		case "age-cloudflared":
			p.Host = inspect(ageHost)
			p.Host.Path = ageHost
		case "gpg-public", "gpg-master", "gpg-subkeys", "gpg-ownertrust", "age-readme", "checksums":
			p.Host = sideInfo{Path: "", Presence: presentMissing}
		default:
			if p.HostRel != "" {
				p.Host = inspect(filepath.Join(home, p.HostRel))
			}
		}
		if res.USBReady && p.USBRel != "" {
			p.USB = inspect(filepath.Join(res.IdentityDir, p.USBRel))
		}
		classify(p, res.USBReady)
		switch p.Status {
		case statusMatch:
			res.Match++
		case statusDiff:
			res.Diff++
		case statusHostOnly:
			res.HostOnly++
		case statusUSBOnly:
			res.USBOnly++
		}
	}

	if res.USBReady {
		res.TarArchives = findTarArchives(mount)
		ok, note := verifyChecksumFile(res.IdentityDir)
		res.ChecksumOK = ok
		res.ChecksumNote = note
	}
	return res
}

func findTarArchives(mount string) []string {
	var out []string
	_ = filepath.Walk(mount, func(path string, info os.FileInfo, err error) error {
		if err != nil || info == nil {
			return nil
		}
		if info.IsDir() {
			rel, _ := filepath.Rel(mount, path)
			if strings.Count(rel, string(os.PathSeparator)) >= 5 {
				return filepath.SkipDir
			}
			return nil
		}
		if info.Mode()&os.ModeSymlink != 0 {
			return nil
		}
		name := info.Name()
		if strings.HasPrefix(name, "credential-backup-v1-") && strings.HasSuffix(name, ".tar") {
			rel, err := filepath.Rel(mount, path)
			if err == nil {
				out = append(out, rel)
			}
		}
		return nil
	})
	return out
}

func verifyChecksumFile(identityDir string) (*bool, string) {
	sumPath := filepath.Join(identityDir, "checksums", "SHA256SUMS")
	data, err := os.ReadFile(sumPath)
	if err != nil {
		return nil, "no SHA256SUMS"
	}
	ok := true
	checked := 0
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) < 2 {
			continue
		}
		want, rel := parts[0], parts[len(parts)-1]
		rel = strings.TrimPrefix(rel, "./")
		got, err := fileSHA256(filepath.Join(identityDir, rel))
		checked++
		if err != nil || !strings.EqualFold(got, want) {
			ok = false
		}
	}
	flag := ok
	if checked == 0 {
		return nil, "SHA256SUMS is empty"
	}
	if ok {
		return &flag, fmt.Sprintf("checksums ok (%d)", checked)
	}
	return &flag, fmt.Sprintf("checksum mismatch (%d files)", checked)
}

func shortHash(h string) string {
	if len(h) < 12 {
		return h
	}
	return h[:12]
}

func formatSide(info sideInfo) string {
	if info.Presence == presentMissing {
		return "—"
	}
	if info.Presence == presentDir {
		return fmt.Sprintf("dir %04o", info.Mode)
	}
	if info.Hash != "" {
		return fmt.Sprintf("%dB %04o %s", info.Size, info.Mode, shortHash(info.Hash))
	}
	return fmt.Sprintf("%dB %04o", info.Size, info.Mode)
}
