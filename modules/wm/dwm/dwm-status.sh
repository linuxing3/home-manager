# Status text for dwm's bar (RAM + clock, oxwm colors via the WM scheme).

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

while true; do
  mem="$(free -g | awk '/^Mem:/ { printf "M: %s/%s GB", $3, $2 }')"
  dt="$(date '+%a, %b %d - %I:%M %P')"
  xsetroot -name "  ${mem}  |  ${dt}  "
  sleep 5
done
