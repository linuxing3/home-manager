package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func copyRegularFile(src, dst string, mode os.FileMode) error {
	st, err := os.Lstat(src)
	if err != nil {
		return err
	}
	if st.Mode()&os.ModeSymlink != 0 || !st.Mode().IsRegular() {
		return fmt.Errorf("refusing to copy non-regular file: %s", src)
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o700); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	tmp := dst + ".partial-" + fmt.Sprintf("%d", os.Getpid())
	out, err := os.OpenFile(tmp, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		_ = out.Close()
		_ = os.Remove(tmp)
		return err
	}
	if err := out.Chmod(mode); err != nil {
		_ = out.Close()
		_ = os.Remove(tmp)
		return err
	}
	if err := out.Close(); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, dst)
}

func backupPair(res scanResult, p secretPair) error {
	if !res.USBReady {
		return fmt.Errorf("KEYVAULT is not mounted")
	}
	dst := filepath.Join(res.IdentityDir, p.USBRel)
	switch p.Kind {
	case "file":
		if p.Host.Presence != presentFile {
			return fmt.Errorf("%s is missing on the host", p.Label)
		}
		return copyRegularFile(p.Host.Path, dst, p.USBMode)
	case "gpg-asc":
		return backupGPG(res, p)
	case "dir":
		if p.ID == "gpg-host" {
			return backupGPGBundle(res)
		}
		return fmt.Errorf("directory copy is not supported for %s", p.Label)
	default:
		return fmt.Errorf("cannot backup %s", p.Label)
	}
}

func restorePair(res scanResult, p secretPair) error {
	if !res.USBReady {
		return fmt.Errorf("KEYVAULT is not mounted")
	}
	src := filepath.Join(res.IdentityDir, p.USBRel)
	switch p.Kind {
	case "file":
		if p.USB.Presence != presentFile {
			return fmt.Errorf("%s is missing on USB", p.Label)
		}
		if p.HostRel == "" && p.ID != "age-api-keys" {
			return fmt.Errorf("%s has no host destination (USB-only material)", p.Label)
		}
		dst := p.Host.Path
		if p.HostRel != "" {
			home, err := os.UserHomeDir()
			if err != nil {
				return err
			}
			dst = filepath.Join(home, p.HostRel)
		}
		if dst == "" && p.ID == "age-api-keys" {
			repo := strings.TrimSpace(os.Getenv("KEYVAULT_REPO"))
			if repo == "" {
				repo = "/share/data/sources/home-config"
			}
			dst = filepath.Join(repo, "security/secrets/api-keys-new.age")
		}
		if dst == "" {
			return fmt.Errorf("no host path for %s", p.Label)
		}
		return copyRegularFile(src, dst, p.HostMode)
	case "gpg-asc":
		return restoreGPG(src, p)
	case "dir":
		return fmt.Errorf("restore GnuPG from armored USB files (public/master/ownertrust), not the raw homedir")
	default:
		return fmt.Errorf("cannot restore %s", p.Label)
	}
}

func gpgBin() string {
	if v := os.Getenv("KEYVAULT_GPG"); v != "" {
		return v
	}
	return "gpg"
}

func backupGPG(res scanResult, p secretPair) error {
	dst := filepath.Join(res.IdentityDir, p.USBRel)
	if err := os.MkdirAll(filepath.Dir(dst), 0o700); err != nil {
		return err
	}
	var cmd *exec.Cmd
	switch p.ID {
	case "gpg-public":
		cmd = exec.Command(gpgBin(), "--batch", "--yes", "--export", "--armor")
	case "gpg-master":
		cmd = exec.Command(gpgBin(), "--batch", "--yes", "--export-secret-keys", "--armor")
	case "gpg-subkeys":
		cmd = exec.Command(gpgBin(), "--batch", "--yes", "--export-secret-subkeys", "--armor")
	case "gpg-ownertrust":
		cmd = exec.Command(gpgBin(), "--batch", "--yes", "--export-ownertrust")
	default:
		return fmt.Errorf("unknown gpg item")
	}
	out, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("gpg export failed: %w", err)
	}
	tmp := dst + ".partial"
	if err := os.WriteFile(tmp, out, p.USBMode); err != nil {
		return err
	}
	return os.Rename(tmp, dst)
}

func backupGPGBundle(res scanResult) error {
	for _, id := range []string{"gpg-public", "gpg-master", "gpg-ownertrust"} {
		for _, p := range res.Pairs {
			if p.ID == id {
				if err := backupGPG(res, p); err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func restoreGPG(src string, p secretPair) error {
	st, err := os.Lstat(src)
	if err != nil {
		return err
	}
	if !st.Mode().IsRegular() {
		return fmt.Errorf("gpg source is not a regular file")
	}
	var cmd *exec.Cmd
	switch p.ID {
	case "gpg-ownertrust":
		cmd = exec.Command(gpgBin(), "--import-ownertrust", src)
	default:
		cmd = exec.Command(gpgBin(), "--batch", "--yes", "--import", src)
	}
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("gpg import failed: %s", strings.TrimSpace(string(out)))
	}
	return nil
}

func writeChecksums(res scanResult) error {
	if !res.USBReady {
		return fmt.Errorf("KEYVAULT is not mounted")
	}
	dir := filepath.Join(res.IdentityDir, "checksums")
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	var b strings.Builder
	err := filepath.Walk(res.IdentityDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info == nil {
			return err
		}
		if info.IsDir() || !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 {
			return nil
		}
		rel, err := filepath.Rel(res.IdentityDir, path)
		if err != nil {
			return err
		}
		if rel == filepath.Join("checksums", "SHA256SUMS") {
			return nil
		}
		sum, err := fileSHA256(path)
		if err != nil {
			return err
		}
		fmt.Fprintf(&b, "%s  %s\n", sum, rel)
		return nil
	})
	if err != nil {
		return err
	}
	dst := filepath.Join(dir, "SHA256SUMS")
	tmp := dst + ".partial"
	if err := os.WriteFile(tmp, []byte(b.String()), 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, dst)
}

func backupAllFiles(res scanResult) (int, error) {
	n := 0
	for _, p := range res.Pairs {
		if p.Kind != "file" || p.Host.Presence != presentFile || p.USBRel == "" {
			continue
		}
		if p.ID == "checksums" {
			continue
		}
		if err := backupPair(res, p); err != nil {
			return n, err
		}
		n++
	}
	if err := writeChecksums(res); err != nil {
		return n, err
	}
	return n, nil
}

func restoreAllFiles(res scanResult) (int, error) {
	n := 0
	for _, p := range res.Pairs {
		if p.Kind != "file" {
			continue
		}
		if p.HostRel == "" && p.ID != "age-api-keys" {
			continue
		}
		if p.USB.Presence != presentFile {
			continue
		}
		if err := restorePair(res, p); err != nil {
			return n, err
		}
		n++
	}
	return n, nil
}

func statusLine(res scanResult) string {
	usb := "USB unmounted"
	if res.USBReady {
		usb = res.IdentityDir
	}
	parts := []string{
		fmt.Sprintf("match %d", res.Match),
		fmt.Sprintf("diff %d", res.Diff),
		fmt.Sprintf("host-only %d", res.HostOnly),
		fmt.Sprintf("usb-only %d", res.USBOnly),
	}
	if res.ChecksumNote != "" {
		parts = append(parts, res.ChecksumNote)
	}
	if len(res.TarArchives) > 0 {
		parts = append(parts, fmt.Sprintf("tars %d", len(res.TarArchives)))
	}
	msg := strings.Join(parts, " · ")
	if res.USBMessage != "" && !res.USBReady {
		return res.USBMessage + " · " + msg
	}
	return usb + " · " + msg
}
