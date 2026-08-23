package main

import "testing"

func TestClassifyMatch(t *testing.T) {
	p := secretPair{
		Kind: "file",
		Host: sideInfo{Presence: presentFile, Hash: "abc"},
		USB:  sideInfo{Presence: presentFile, Hash: "abc"},
	}
	classify(&p, true)
	if p.Status != statusMatch {
		t.Fatalf("got %s", p.Status)
	}
}

func TestClassifyDiff(t *testing.T) {
	p := secretPair{
		Kind: "file",
		Host: sideInfo{Presence: presentFile, Hash: "aaa"},
		USB:  sideInfo{Presence: presentFile, Hash: "bbb"},
	}
	classify(&p, true)
	if p.Status != statusDiff {
		t.Fatalf("got %s", p.Status)
	}
}

func TestClassifyHostOnly(t *testing.T) {
	p := secretPair{
		Kind: "file",
		Host: sideInfo{Presence: presentFile, Hash: "aaa"},
		USB:  sideInfo{Presence: presentMissing},
	}
	classify(&p, true)
	if p.Status != statusHostOnly {
		t.Fatalf("got %s", p.Status)
	}
}
