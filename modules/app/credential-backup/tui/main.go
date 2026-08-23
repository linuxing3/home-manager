package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	if len(os.Args) > 1 && (os.Args[1] == "--scan" || os.Args[1] == "-scan") {
		res := scanAll()
		fmt.Println(statusLine(res))
		for _, p := range res.Pairs {
			fmt.Printf("%-10s  %-28s  host=%-28s  usb=%s\n", p.Status, p.Label, formatSide(p.Host), formatSide(p.USB))
		}
		if len(res.TarArchives) > 0 {
			fmt.Println("usb tars:")
			for _, a := range res.TarArchives {
				fmt.Println("  " + a)
			}
		}
		return
	}

	p := tea.NewProgram(newModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "keyvault-tui: %v\n", err)
		os.Exit(1)
	}
}
