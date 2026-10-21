package main

import (
	"context"
	"testing"
)

func TestGroupAndFilter(t *testing.T) {
	raw := "" +
		"Id=agenix.service\nDescription=Agenix secrets\nActiveState=active\nSubState=running\nUnitFileState=enabled\nFragmentPath=/nix/store/x/agenix.service\n\n" +
		"Id=cloudflared-office.service\nDescription=office tunnel\nActiveState=inactive\nSubState=dead\nUnitFileState=enabled\nFragmentPath=/home/a/.config/systemd/user/cloudflared-office.service\n\n" +
		"Id=orca.service\nDescription=Orca\nActiveState=active\nSubState=running\nUnitFileState=enabled\nFragmentPath=/nix/store/y/orca.service\n\n" +
		"Id=pipewire.service\nDescription=pipewire\nActiveState=active\nSubState=running\nUnitFileState=enabled\nFragmentPath=/nix/store/z/pipewire.service\n\n" +
		"Id=dbus.service\nDescription=dbus\nActiveState=active\nSubState=running\nUnitFileState=static\nFragmentPath=/usr/lib/systemd/user/dbus.service\n\n" +
		"Id=greetd.service\nDescription=greetd\nActiveState=active\nSubState=running\nUnitFileState=enabled\nFragmentPath=/etc/systemd/system/greetd.service\n"
	user := parseShow(raw, "user")
	names := map[string]string{}
	for _, u := range user {
		names[u.Name] = u.Group
	}
	if names["agenix.service"] != "secrets" || names["cloudflared-office.service"] != "tunnels" || names["orca.service"] != "agents" {
		t.Fatalf("groups: %#v", names)
	}
	if _, ok := names["pipewire.service"]; ok {
		t.Fatal("pipewire should be hidden")
	}
	if _, ok := names["dbus.service"]; ok {
		t.Fatal("dbus should be hidden")
	}
	sys := parseShow("Id=greetd.service\nDescription=greetd\nActiveState=active\nSubState=running\nUnitFileState=enabled\nFragmentPath=/etc/systemd/system/greetd.service\n", "system")
	if len(sys) != 1 || sys[0].Group != "session" || !sys[0].Switchable {
		t.Fatalf("greetd: %#v", sys)
	}
	if parseShow("Id=evil.service\nActiveState=inactive\nFragmentPath=/tmp/x\n", "system") != nil {
		t.Fatal("unknown system unit must be dropped")
	}
}

func TestRefuseBadAction(t *testing.T) {
	a := &App{}
	if a.switchUnit(context.Background(), "agenix.service;id", "start").OK {
		t.Fatal("bad name accepted")
	}
	if a.switchUnit(context.Background(), "system-panel.service", "stop").OK {
		t.Fatal("self stop accepted")
	}
	if a.switchUnit(context.Background(), "../etc/passwd", "start").OK {
		t.Fatal("path accepted")
	}
}
