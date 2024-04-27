__main() {
    local major="${BASH_VERSINFO[0]}"
    local minor="${BASH_VERSINFO[1]}"

    if ((major > 4)) || { ((major == 4)) && ((minor >= 1)); }; then
        source <(/home/vagrant/.nix-profile/bin/starship init bash --print-full-init)
    else
        source /dev/stdin <<<"$(/home/vagrant/.nix-profile/bin/starship init bash --print-full-init)"
    fi
}
__main
unset -f __main
