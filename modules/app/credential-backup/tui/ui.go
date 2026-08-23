package main

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type focusArea int

const (
	focusMenu focusArea = iota
	focusHost
	focusUSB
	focusButtons
)

type confirmKind int

const (
	confirmNone confirmKind = iota
	confirmRestoreSelected
	confirmRestoreAll
	confirmBackupGPG
)

type buttonID int

const (
	btnBackup buttonID = iota
	btnRestore
	btnRefresh
	btnChecksums
	btnVault
)

var buttonLabels = []string{"Backup → USB", "Restore → Host", "Refresh", "Checksums", "Vault backup"}

type menuItem struct {
	label  string
	hint   string
	action string
}

var menus = []struct {
	title string
	items []menuItem
}{
	{
		title: "Actions",
		items: []menuItem{
			{"Backup selected → USB", "b", "backup-sel"},
			{"Backup all files → USB", "B", "backup-all"},
			{"Export GPG → USB", "g", "backup-gpg"},
			{"Restore selected → host", "r", "restore-sel"},
			{"Restore all files → host", "R", "restore-all"},
			{"Import selected GPG", "", "restore-gpg"},
			{"Write SHA256SUMS", "c", "checksums"},
			{"Quit", "q", "quit"},
		},
	},
	{
		title: "Vault",
		items: []menuItem{
			{"credential-vault backup", "v", "vault-backup"},
			{"credential-vault list", "", "vault-list"},
			{"credential-vault restore latest", "", "vault-restore"},
		},
	},
	{
		title: "USB",
		items: []menuItem{
			{"Refresh scan", "f", "refresh"},
			{"List USB tar archives", "t", "usb-list"},
			{"Restore latest USB tar", "", "usb-restore"},
		},
	},
}

type model struct {
	width, height int
	focus         focusArea
	menuOpen      bool
	menuIndex     int
	itemIndex     int
	row           int
	button        int
	scan          scanResult
	hostVP        viewport.Model
	usbVP         viewport.Model
	status        string
	err           string
	confirm       confirmKind
	lastAction    string
}

type scanMsg struct{ result scanResult }
type doneMsg struct{ text string }
type failMsg struct{ err error }

func newModel() model {
	return model{
		focus:  focusHost,
		hostVP: viewport.New(40, 10),
		usbVP:  viewport.New(40, 10),
		status: "scanning…",
	}
}

func (m model) Init() tea.Cmd {
	return refreshCmd
}

func refreshCmd() tea.Msg {
	return scanMsg{result: scanAll()}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.layoutViewports()
		m.refreshPanes()
		return m, nil
	case scanMsg:
		m.scan = msg.result
		m.err = ""
		if m.row >= len(m.scan.Pairs) {
			m.row = 0
		}
		m.status = statusLine(m.scan)
		m.refreshPanes()
		return m, nil
	case doneMsg:
		m.lastAction = msg.text
		m.status = msg.text
		m.confirm = confirmNone
		return m, refreshCmd
	case failMsg:
		m.err = msg.err.Error()
		m.status = "error: " + m.err
		m.confirm = confirmNone
		return m, nil
	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.confirm != confirmNone {
		switch msg.String() {
		case "y", "Y", "enter":
			return m, m.runConfirm()
		case "n", "N", "esc", "q":
			m.confirm = confirmNone
			m.status = "cancelled"
			return m, nil
		}
		return m, nil
	}
	if m.menuOpen {
		switch msg.String() {
		case "esc", "q":
			m.menuOpen = false
			return m, nil
		case "up", "k":
			if m.itemIndex > 0 {
				m.itemIndex--
			}
			return m, nil
		case "down", "j":
			items := menus[m.menuIndex].items
			if m.itemIndex < len(items)-1 {
				m.itemIndex++
			}
			return m, nil
		case "enter", " ":
			action := menus[m.menuIndex].items[m.itemIndex].action
			m.menuOpen = false
			return m.dispatch(action)
		case "left", "h":
			if m.menuIndex > 0 {
				m.menuIndex--
				m.itemIndex = 0
			}
			return m, nil
		case "right", "l":
			if m.menuIndex < len(menus)-1 {
				m.menuIndex++
				m.itemIndex = 0
			}
			return m, nil
		}
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit
	case "tab":
		m.focus = (m.focus + 1) % 4
		return m, nil
	case "shift+tab":
		m.focus = (m.focus + 3) % 4
		return m, nil
	case "f5", "f":
		m.status = "scanning…"
		return m, refreshCmd
	case "b":
		return m.dispatch("backup-sel")
	case "B":
		return m.dispatch("backup-all")
	case "r":
		return m.dispatch("restore-sel")
	case "R":
		return m.dispatch("restore-all")
	case "c":
		return m.dispatch("checksums")
	case "g":
		return m.dispatch("backup-gpg")
	case "v":
		return m.dispatch("vault-backup")
	case "t":
		return m.dispatch("usb-list")
	case "down", "j":
		if m.focus == focusButtons {
			return m, nil
		}
		if m.row < len(m.scan.Pairs)-1 {
			m.row++
			m.refreshPanes()
		}
		return m, nil
	case "up", "k":
		if m.row > 0 {
			m.row--
			m.refreshPanes()
		}
		return m, nil
	case "left", "h":
		if m.focus == focusButtons && m.button > 0 {
			m.button--
		} else if m.focus == focusUSB {
			m.focus = focusHost
		} else if m.focus == focusMenu && m.menuIndex > 0 {
			m.menuIndex--
		}
		return m, nil
	case "right", "l":
		if m.focus == focusButtons && m.button < len(buttonLabels)-1 {
			m.button++
		} else if m.focus == focusHost {
			m.focus = focusUSB
		} else if m.focus == focusMenu && m.menuIndex < len(menus)-1 {
			m.menuIndex++
		}
		return m, nil
	case "enter", " ":
		return m.activate()
	}
	return m, nil
}

func (m model) activate() (tea.Model, tea.Cmd) {
	switch m.focus {
	case focusMenu:
		m.menuOpen = true
		m.itemIndex = 0
		return m, nil
	case focusButtons:
		switch buttonID(m.button) {
		case btnBackup:
			return m.dispatch("backup-sel")
		case btnRestore:
			return m.dispatch("restore-sel")
		case btnRefresh:
			return m.dispatch("refresh")
		case btnChecksums:
			return m.dispatch("checksums")
		case btnVault:
			return m.dispatch("vault-backup")
		}
	case focusHost:
		return m.dispatch("backup-sel")
	case focusUSB:
		return m.dispatch("restore-sel")
	}
	return m, nil
}

func (m model) dispatch(action string) (tea.Model, tea.Cmd) {
	switch action {
	case "quit":
		return m, tea.Quit
	case "refresh":
		m.status = "scanning…"
		return m, refreshCmd
	case "backup-sel":
		return m, m.doBackupSelected()
	case "backup-all":
		return m, func() tea.Msg {
			n, err := backupAllFiles(m.scan)
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: fmt.Sprintf("backed up %d host files to USB and wrote checksums", n)}
		}
	case "restore-sel":
		m.confirm = confirmRestoreSelected
		m.status = "Restore selected USB file onto the host? [y/N]"
		return m, nil
	case "restore-all":
		m.confirm = confirmRestoreAll
		m.status = "Restore ALL matching USB files onto the host? [y/N]"
		return m, nil
	case "backup-gpg":
		m.confirm = confirmBackupGPG
		m.status = "Export GPG public/secret/ownertrust onto USB? [y/N]"
		return m, nil
	case "restore-gpg":
		return m, m.doRestoreGPG()
	case "checksums":
		return m, func() tea.Msg {
			if err := writeChecksums(m.scan); err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "wrote checksums/SHA256SUMS"}
		}
	case "vault-backup":
		return m, tea.ExecProcess(exec.Command("credential-vault", "backup"), func(err error) tea.Msg {
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "credential-vault backup finished"}
		})
	case "vault-list":
		return m, tea.ExecProcess(exec.Command("credential-vault", "list"), func(err error) tea.Msg {
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "credential-vault list finished"}
		})
	case "vault-restore":
		return m, tea.ExecProcess(exec.Command("credential-vault", "restore", "latest"), func(err error) tea.Msg {
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "credential-vault restore finished"}
		})
	case "usb-list":
		return m, tea.ExecProcess(exec.Command("credential-usb-recovery", "list"), func(err error) tea.Msg {
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "USB tar list finished"}
		})
	case "usb-restore":
		return m, tea.ExecProcess(exec.Command("credential-usb-recovery", "restore", "latest"), func(err error) tea.Msg {
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "USB tar restore finished"}
		})
	}
	return m, nil
}

func (m model) runConfirm() tea.Cmd {
	switch m.confirm {
	case confirmRestoreSelected:
		return m.doRestoreSelected()
	case confirmRestoreAll:
		return func() tea.Msg {
			n, err := restoreAllFiles(m.scan)
			if err != nil {
				return failMsg{err}
			}
			return doneMsg{text: fmt.Sprintf("restored %d files from USB to host", n)}
		}
	case confirmBackupGPG:
		return func() tea.Msg {
			if err := backupGPGBundle(m.scan); err != nil {
				return failMsg{err}
			}
			if err := writeChecksums(m.scan); err != nil {
				return failMsg{err}
			}
			return doneMsg{text: "exported GPG material to USB"}
		}
	default:
		return nil
	}
}

func (m model) currentPair() (secretPair, bool) {
	if m.row < 0 || m.row >= len(m.scan.Pairs) {
		return secretPair{}, false
	}
	return m.scan.Pairs[m.row], true
}

func (m model) doBackupSelected() tea.Cmd {
	p, ok := m.currentPair()
	if !ok {
		return func() tea.Msg { return failMsg{fmt.Errorf("no row selected")} }
	}
	return func() tea.Msg {
		if err := backupPair(m.scan, p); err != nil {
			return failMsg{err}
		}
		if err := writeChecksums(m.scan); err != nil {
			return failMsg{err}
		}
		return doneMsg{text: "backed up " + p.Label}
	}
}

func (m model) doRestoreSelected() tea.Cmd {
	p, ok := m.currentPair()
	if !ok {
		return func() tea.Msg { return failMsg{fmt.Errorf("no row selected")} }
	}
	return func() tea.Msg {
		if err := restorePair(m.scan, p); err != nil {
			return failMsg{err}
		}
		return doneMsg{text: "restored " + p.Label}
	}
}

func (m model) doRestoreGPG() tea.Cmd {
	p, ok := m.currentPair()
	if !ok || p.Kind != "gpg-asc" {
		return func() tea.Msg { return failMsg{fmt.Errorf("select a GPG armored row")} }
	}
	return func() tea.Msg {
		if err := restorePair(m.scan, p); err != nil {
			return failMsg{err}
		}
		return doneMsg{text: "imported " + p.Label}
	}
}

func (m *model) layoutViewports() {
	paneW := max(20, (m.width-3)/2)
	paneH := max(6, m.height-8)
	m.hostVP.Width = paneW
	m.hostVP.Height = paneH
	m.usbVP.Width = paneW
	m.usbVP.Height = paneH
}

func (m *model) refreshPanes() {
	hostLines := make([]string, 0, len(m.scan.Pairs))
	usbLines := make([]string, 0, len(m.scan.Pairs))
	for i, p := range m.scan.Pairs {
		marker := "  "
		if i == m.row {
			marker = "> "
		}
		usbPath := p.USBRel
		hostLines = append(hostLines, fmt.Sprintf("%s%-22s %s", marker, trunc(p.Label, 22), formatSide(p.Host)))
		usbLines = append(usbLines, fmt.Sprintf("%s%-22s %s %s", marker, trunc(usbPath, 22), formatSide(p.USB), p.Status))
	}
	m.hostVP.SetContent(strings.Join(hostLines, "\n"))
	m.usbVP.SetContent(strings.Join(usbLines, "\n"))
	if m.row >= 0 {
		m.hostVP.SetYOffset(max(0, m.row-m.hostVP.Height/2))
		m.usbVP.SetYOffset(max(0, m.row-m.usbVP.Height/2))
	}
}

func trunc(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n-1] + "…"
}

var (
	titleStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("51"))
	activeBorder = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("51"))
	idleBorder   = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("240"))
	menuStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("252"))
	menuActive   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("0")).Background(lipgloss.Color("51"))
	dropStyle    = lipgloss.NewStyle().Border(lipgloss.NormalBorder()).BorderForeground(lipgloss.Color("51")).Padding(0, 1)
	statusOK     = lipgloss.NewStyle().Foreground(lipgloss.Color("82"))
	statusErr    = lipgloss.NewStyle().Foreground(lipgloss.Color("196"))
	hintStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("244"))
	btnIdle      = lipgloss.NewStyle().Foreground(lipgloss.Color("252")).Padding(0, 1).Border(lipgloss.NormalBorder())
	btnActive    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("0")).Background(lipgloss.Color("51")).Padding(0, 1).Border(lipgloss.NormalBorder())
)

func (m model) View() string {
	if m.width == 0 {
		return "loading…"
	}
	menu := m.renderMenuBar()
	hostTitle := titleStyle.Render(" Host secrets")
	usbTitle := titleStyle.Render(" USB KeyVault")
	if m.scan.USBReady {
		usbTitle = titleStyle.Render(" USB " + m.scan.IdentityName)
	}
	hostBox := m.paneBox(focusHost, hostTitle+"\n"+m.hostVP.View())
	usbBox := m.paneBox(focusUSB, usbTitle+"\n"+m.usbVP.View())
	panes := lipgloss.JoinHorizontal(lipgloss.Top, hostBox, usbBox)
	status := m.status
	if m.err != "" {
		status = statusErr.Render(m.err)
	} else if m.scan.Diff == 0 && m.scan.USBReady {
		status = statusOK.Render(m.status)
	}
	help := hintStyle.Render("tab focus · enter activate · b/B backup · r/R restore · c checksums · v vault · q quit")
	body := lipgloss.JoinVertical(lipgloss.Left, menu, panes, m.renderButtons(), status, help)
	if m.menuOpen {
		drop := m.renderDropdown()
		body = overlayTopLeft(body, drop, 2, 1)
	}
	if m.confirm != confirmNone {
		body = overlayCenter(body, m.renderConfirm())
	}
	return body
}

func (m model) paneBox(area focusArea, content string) string {
	style := idleBorder
	if m.focus == area {
		style = activeBorder
	}
	w := max(20, (m.width-2)/2)
	return style.Width(w - 2).Render(content)
}

func (m model) renderMenuBar() string {
	parts := make([]string, 0, len(menus))
	for i, menu := range menus {
		label := " " + menu.title + " ▾ "
		if m.focus == focusMenu && i == m.menuIndex {
			parts = append(parts, menuActive.Render(label))
		} else {
			parts = append(parts, menuStyle.Render(label))
		}
	}
	return strings.Join(parts, "  ")
}

func (m model) renderDropdown() string {
	menu := menus[m.menuIndex]
	lines := make([]string, 0, len(menu.items))
	for i, item := range menu.items {
		prefix := "  "
		if i == m.itemIndex {
			prefix = "> "
		}
		hint := ""
		if item.hint != "" {
			hint = "  [" + item.hint + "]"
		}
		lines = append(lines, prefix+item.label+hint)
	}
	return dropStyle.Render(strings.Join(lines, "\n"))
}

func (m model) renderButtons() string {
	parts := make([]string, 0, len(buttonLabels))
	for i, label := range buttonLabels {
		style := btnIdle
		if m.focus == focusButtons && i == m.button {
			style = btnActive
		}
		parts = append(parts, style.Render(label))
	}
	return strings.Join(parts, " ")
}

func (m model) renderConfirm() string {
	return dropStyle.Render("Confirm: " + m.status + "\nEnter/y yes · n/esc no")
}

func overlayTopLeft(base, overlay string, x, y int) string {
	baseLines := strings.Split(base, "\n")
	overLines := strings.Split(overlay, "\n")
	for i, line := range overLines {
		row := y + i
		if row < 0 || row >= len(baseLines) {
			continue
		}
		runes := []rune(baseLines[row])
		ol := []rune(line)
		for j, r := range ol {
			col := x + j
			for len(runes) <= col {
				runes = append(runes, ' ')
			}
			if col >= 0 && col < len(runes) {
				runes[col] = r
			}
		}
		baseLines[row] = string(runes)
	}
	return strings.Join(baseLines, "\n")
}

func overlayCenter(base, overlay string) string {
	return lipgloss.Place(lipgloss.Width(base), lipgloss.Height(base), lipgloss.Center, lipgloss.Center, overlay)
}
