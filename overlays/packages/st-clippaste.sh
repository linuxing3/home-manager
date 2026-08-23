#!/bin/sh
# Read CLIPBOARD for st: paste text, or write image/* to a runtime file and paste its path.
sel=${1:-clipboard}
targets=$(xclip -selection "$sel" -o -t TARGETS 2>/dev/null || true)

has() {
  printf '%s\n' "$targets" | grep -Fxq "$1"
}

if has UTF8_STRING || has text/plain || has STRING; then
  if has UTF8_STRING; then
    xclip -selection "$sel" -o -t UTF8_STRING
  else
    xclip -selection "$sel" -o
  fi
  exit 0
fi

mime=
for t in image/png image/jpeg image/jpg image/webp image/gif; do
  if has "$t"; then
    mime=$t
    break
  fi
done
[ -n "$mime" ] || exit 0

case "$mime" in
  image/jpeg | image/jpg) ext=jpg ;;
  image/webp) ext=webp ;;
  image/gif) ext=gif ;;
  *) ext=png ;;
esac

dir=${XDG_RUNTIME_DIR:-/tmp}
path=$dir/st-clipboard.$ext
xclip -selection "$sel" -o -t "$mime" >"$path" || exit 0
[ -s "$path" ] || exit 0
printf '%s' "$path"
