{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  # qmd = pkgs.callPackage ../pkgs/qmd.nix {
  #   src = inputs.qmd.outPath;
  # };
in {
  
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    steel

    # greeter
    cage
    greetd
    tuigreet

    # dev
    devenv

    # lsp and formatter
    taplo
    typos-lsp
    stylua
    lua-language-server
    nil
    nixd
    alejandra
    kotlin-language-server

    # better ls
    eza

    # web in console
    file
    wmctrl
    jshon
    aria
    lynx
    elinks
    ddgr

    # speech (OpenAI Whisper CLI)
    python3Packages.openai-whisper

    # mail in console
    mw
    mu
    neomutt
    himalaya
    isync
    msmtp
    getmail6
    notmuch
    abook
    mpop

    envsubst
    pass
    w3m

    # for markdown
    glow
    lowdown

    # note
    zk

    # launcher
    rofi
    eww

    picom
    feh
    acpi
    dash

    # file transfer
    croc

    # Command Line
    onefetch
    disfetch

    lolcat
    cowsay
    starfetch
    cava
    killall
    libnotify
    timer
    brightnessctl

    gnugrep
    gnused
    gnumake
    bc

    # file viewer
    pistol

    # archive tool / viewer
    zip
    unzip
    atool

    chafa
    lesspipe

    # youtube downloader
    yt-dlp

    # images
    grim
    slurp
    maim
    epub-thumbnailer
    imagemagick
    ueberzug

    # productivity
    bat
    fd
    ripgrep
    bottom
    btop
    rsync
    hledger

    hunspell
    hunspellDicts.en_US-large

    # json/toml/yml
    jq
    yq

    # converters
    pandoc

    # info/utils
    hwinfo
    pciutils
    numbat

    # mp4
    smplayer
    ffmpegthumbnailer
    mediainfo
    exiftool
    # odt
    odt2txt

    # pdf
    zathura
    tdf

    # djvu
    djvulibre

    cbonsai # terminal screensaver
    cmatrix
    pipes # terminal screensaver
    sl
    tty-clock # cli clock

    libevdev
    libinput
    cpio
    udev
    openssl
    protobuf
    stunnel

    # viewer
    inputs.doxx.packages.${system}.default
    inputs.xleak.packages.${system}.default
    # qmd

    # MCP servers
    # lancedb-mcp

    # MCP toolchain
    # openfang

    # Open Design
    open-design

    # Lightpanda + agent browser (native CLIs)
    lightpanda
    agent-browser

    # NotebookLM unofficial CLI/API
    notebooklm-py
    notebooklm-client

    # Hermes Web UI CLI
    hermes-web-ui

    # jcode coding agent
    jcode
  ];
}
