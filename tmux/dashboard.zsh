#!/usr/bin/env zsh
#
# tmux dashboard — v1 (plain text, two-column grid)
#
# Left column:  clock, date, weather (current + forecast)
# Right column: widgets (disk, wifi, battery, network)
#
# Quit with q or Esc.

emulate -L zsh
setopt multibyte

# ── Colors (256-color codes, applied as `printf '\033[38;5;Nm'`) ────────
clock_color=255
date_color=245
weather_color=220
forecast_color=245
label_color=110
value_color=252
warning_color=214
critical_color=196
accent_color=110
dim_color=240

ansi()  { printf '\033[38;5;%sm' "$1"; }
reset() { printf '\033[0m'; }
bold()  { printf '\033[1m'; }

# ── OS detection ────────────────────────────────────────────────────────
case "$(uname -s)" in
    Darwin) OS=osx ;;
    Linux)  OS=linux ;;
    *)      OS=unknown ;;
esac

# ── Caches ──────────────────────────────────────────────────────────────
forecast_cache="/tmp/tmux_dashboard_forecast"
forecast_ttl=600       # 10 min — j1 provides both current + forecast
widget_refresh_interval=15

cache_age() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local mtime
        mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
        echo $(( $(date +%s) - mtime ))
    else
        echo 999999
    fi
}

refresh_forecast_cache() {
    (( $(cache_age "$forecast_cache") < forecast_ttl )) && return
    (curl -s --max-time 8 "wttr.in/?format=j1" 2>/dev/null > "${forecast_cache}.tmp" \
        && mv "${forecast_cache}.tmp" "$forecast_cache" &)
}

# Temperature → 256-color code. Bands tuned for °C.
temp_color() {
    local t="$1"
    [[ -z "$t" || ! "$t" =~ ^-?[0-9]+$ ]] && { printf '%s' "$value_color"; return; }
    if   (( t < 0  )); then printf '39'   # ice blue
    elif (( t < 10 )); then printf '45'   # cyan / cold
    elif (( t < 18 )); then printf '78'   # light green / mild
    elif (( t < 25 )); then printf '220'  # yellow / warm
    elif (( t < 30 )); then printf '208'  # orange / hot
    else                    printf '196'  # red / very hot
    fi
}

# Convert km/h to knots, rounded to nearest integer.
kmh_to_knots() {
    local kmh="$1"
    [[ -z "$kmh" ]] && { printf '0'; return; }
    printf '%.0f' "$(( kmh * 0.539957 ))"
}

# Returns "code|tempC|feelsC|humidity|windKmh" from j1, or empty.
read_weather_current() {
    [[ ! -f "$forecast_cache" ]] && return
    local json
    json=$(< "$forecast_cache")
    [[ -z "$json" ]] && return
    jq -r '
        .current_condition // [] | .[0] // null |
        if . == null then empty else
            (.weatherCode // "113") + "|" +
            (.temp_C // "?") + "|" +
            (.FeelsLikeC // "?") + "|" +
            (.humidity // "?") + "|" +
            (.windspeedKmph // "0")
        end
    ' <<< "$json" 2>/dev/null
}

# Returns up to 3 lines: "date|max|min|code|rain%|wind_kmh"
# All values come from the midday hourly slice (.hourly[4]) — best representative
# of the day's daytime conditions.
read_forecast() {
    [[ ! -f "$forecast_cache" ]] && return
    local json
    json=$(< "$forecast_cache")
    [[ -z "$json" ]] && return
    jq -r '
        .weather // [] | .[1:4] | map(
            (.date) + "|" +
            (.maxtempC) + "|" +
            (.mintempC) + "|" +
            (.hourly[4].weatherCode // .hourly[0].weatherCode // "113") + "|" +
            (.hourly[4].chanceofrain // "0") + "|" +
            (.hourly[4].windspeedKmph // "0")
        ) | .[]
    ' <<< "$json" 2>/dev/null
}

# WeatherCode → emoji (wttr.in / WWO codes).
emoji_for_code() {
    case "$1" in
        113)                                  printf '☀️ ' ;;   # sunny
        116)                                  printf '⛅ ' ;;   # partly cloudy
        119|122)                              printf '☁️ ' ;;   # cloudy
        143|248|260)                          printf '🌫️ ' ;;   # mist/fog
        176|263|266|281|284|293|353)          printf '🌦️ ' ;;   # light rain / showers
        296|299|302|305|308|311|314|317|356|359) printf '🌧️ ' ;;   # rain
        179|182|185|227|230|320|323|326|329|332|335|338|350|362|365|368|371|374|377) printf '🌨️ ' ;;   # snow
        200|386|389|392|395)                  printf '⛈️ ' ;;   # thunder
        *)                                    printf '· ' ;;
    esac
}

# ── Widget data readers (raw scripts emit `state\nvalue`) ───────────────
BATTERY_STATE=''  BATTERY_VALUE=''
FREESPACE_STATE='' FREESPACE_VALUE=''
WIFI_STATE=''     WIFI_VALUE=''
NETWORK_LABEL=''

read_widget_data() {
    BATTERY_STATE=''; BATTERY_VALUE=''
    if [[ -f "$HOME/.dotfiles/tmux/battery.$OS.zsh" ]]; then
        local out
        out=$("$HOME/.dotfiles/tmux/battery.$OS.zsh" 2>/dev/null)
        BATTERY_STATE=$(sed -n 1p <<< "$out")
        BATTERY_VALUE=$(sed -n 2p <<< "$out")
    fi

    local fout
    fout=$("$HOME/.dotfiles/tmux/free-space.zsh" 2>/dev/null)
    FREESPACE_STATE=$(sed -n 1p <<< "$fout")
    FREESPACE_VALUE=$(sed -n 2p <<< "$fout")

    WIFI_STATE=''; WIFI_VALUE=''
    if [[ -f "$HOME/.dotfiles/tmux/wifi-signal.$OS.zsh" ]]; then
        local wout
        wout=$("$HOME/.dotfiles/tmux/wifi-signal.$OS.zsh" 2>/dev/null)
        WIFI_STATE=$(sed -n 1p <<< "$wout")
        WIFI_VALUE=$(sed -n 2p <<< "$wout")
    fi

    NETWORK_LABEL='Offline'
    if [[ "$OS" == "osx" ]]; then
        local route_result interface
        route_result=$(route get google.de 2>&1)
        if [[ "$route_result" != *"bad address"* ]]; then
            interface=$(grep interface <<< "$route_result" | awk '{print $2}')
            if [[ "$interface" == *"utun"* ]]; then
                NETWORK_LABEL='VPN'
            else
                NETWORK_LABEL=$(networksetup -listnetworkserviceorder 2>/dev/null \
                    | grep "$interface" | sed -E -n 's/.*: (.*),.*/\1/p')
                [[ -z "$NETWORK_LABEL" ]] && NETWORK_LABEL="$interface"
            fi
        fi
    elif [[ "$OS" == "linux" ]]; then
        local interface
        interface=$(ip route get 1.1.1.1 2>/dev/null | grep -oE 'dev [^ ]+' | awk '{print $2}')
        [[ -n "$interface" ]] && NETWORK_LABEL="$interface"
    fi
}

# ── Per-widget formatted strings ────────────────────────────────────────
wifi_bars() {
    case "$WIFI_STATE" in
        excellent) printf '%s' '▂▄▆█' ;;
        good)      printf '%s' '▂▄▆ ' ;;
        fair)      printf '%s' '▂▄   ' ;;
        weak)      printf '%s' '▂    ' ;;
        *)         printf '%s' 'x    ' ;;
    esac
}

wifi_value_color() {
    case "$WIFI_STATE" in
        excellent|good) echo "$value_color" ;;
        fair)           echo "$warning_color" ;;
        weak)           echo "$critical_color" ;;
        *)              echo "$dim_color" ;;
    esac
}

battery_value_color() {
    if [[ "$BATTERY_STATE" == "charging" ]]; then
        echo "$accent_color"
    elif [[ -n "$BATTERY_VALUE" && "$BATTERY_VALUE" -lt 16 ]]; then
        echo "$critical_color"
    elif [[ -n "$BATTERY_VALUE" && "$BATTERY_VALUE" -lt 31 ]]; then
        echo "$warning_color"
    else
        echo "$value_color"
    fi
}

freespace_value_color() {
    case "$FREESPACE_STATE" in
        critical) echo "$critical_color" ;;
        warning)  echo "$warning_color" ;;
        *)        echo "$value_color" ;;
    esac
}

# ── Cursor / screen control ─────────────────────────────────────────────
move_to()     { printf '\033[%d;%dH' "$1" "$2"; }   # row, col (1-based)
clear_to_eol(){ printf '\033[K'; }
clear_all()   { printf '\033[2J'; }
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

# Track rows we've written so we can blank rows that disappear between frames
# (e.g. forecast row count shrinks). Avoids \033[2J — that causes flicker.
typeset -ga DIRTY_ROWS=()
typeset -ga PREV_DIRTY_ROWS=()

# Buffer a write into the frame string at (row, col). Each piece is followed
# by clear-to-EOL so shorter content properly truncates the previous line.
FRAME_BUFFER=''
put() {
    local row=$1 col=$2 text=$3
    FRAME_BUFFER+=$'\033['"${row};${col}"'H'"${text}"$'\033[K'
    DIRTY_ROWS+=("$row")
}

# Emit blanking escapes for rows that were written last frame but not this one.
blank_stale_rows() {
    # NOTE: all locals declared up-front. zsh prints `var=value` if a `local`
    # declaration appears inside a loop body and is followed by an assignment.
    local row stale current
    for row in "${PREV_DIRTY_ROWS[@]}"; do
        stale=1
        for current in "${DIRTY_ROWS[@]}"; do
            if [[ "$current" == "$row" ]]; then
                stale=0
                break
            fi
        done
        if (( stale )); then
            FRAME_BUFFER+=$'\033['"${row};1"'H'$'\033[K'
        fi
    done
}

# ── Render ──────────────────────────────────────────────────────────────
# Layout (1-based rows/cols):
#   Left column starts at col 6.
#   Right column starts at col (COLUMNS / 2).
#   Top padding: 3 rows.
render() {
    # NOTE: declare all locals at function top. zsh prints `var=value` if
    # `local` appears inside a loop body followed by an assignment.
    local terminal_width terminal_height left_col right_col top
    local time_str date_str current forecast_row fl
    local date_part rest max_part min_part code_part rain_part wind_part
    local icon day_label knots
    local row wifi_extra
    local cur_code cur_temp cur_feels cur_humidity cur_wind cur_icon

    terminal_width="${COLUMNS:-80}"
    terminal_height="${LINES:-24}"

    left_col=6
    right_col=$(( terminal_width / 2 ))
    (( right_col < left_col + 30 )) && right_col=$(( left_col + 30 ))

    top=3

    FRAME_BUFFER=''
    DIRTY_ROWS=()

    # Left column ────────────────────────────────────────────────────────
    time_str=$(date '+%H:%M')
    put $top $left_col "$(bold)$(ansi $clock_color)${time_str}$(reset)"

    date_str=$(date '+%A, %-d %B %Y')
    put $(( top + 2 )) $left_col "$(ansi $date_color)${date_str}$(reset)"

    current=$(read_weather_current)
    if [[ -n "$current" ]]; then
        cur_code="${current%%|*}"
        rest="${current#*|}"
        cur_temp="${rest%%|*}"
        rest="${rest#*|}"
        cur_feels="${rest%%|*}"
        rest="${rest#*|}"
        cur_humidity="${rest%%|*}"
        cur_wind="${rest#*|}"
        cur_icon=$(emoji_for_code "$cur_code")
        knots=$(kmh_to_knots "$cur_wind")
        put $(( top + 4 )) $left_col \
            "${cur_icon} $(ansi $(temp_color $cur_temp))${cur_temp}°C$(reset)   $(ansi $dim_color)💧 ${cur_humidity}%  💨 ${cur_wind} km/h (${knots} kn)$(reset)"
    fi

    forecast_row=$(( top + 6 ))
    while IFS= read -r fl; do
        [[ -z "$fl" ]] && continue
        date_part="${fl%%|*}"
        rest="${fl#*|}"
        max_part="${rest%%|*}"
        rest="${rest#*|}"
        min_part="${rest%%|*}"
        rest="${rest#*|}"
        code_part="${rest%%|*}"
        rest="${rest#*|}"
        rain_part="${rest%%|*}"
        wind_part="${rest#*|}"
        icon=$(emoji_for_code "$code_part")
        knots=$(kmh_to_knots "$wind_part")
        day_label=$(date -j -f "%Y-%m-%d" "$date_part" "+%a" 2>/dev/null \
            || date -d "$date_part" "+%a" 2>/dev/null \
            || echo "$date_part")
        put $forecast_row $left_col \
            "$(ansi $forecast_color)${day_label}$(reset)  ${icon} $(ansi $(temp_color $max_part))${max_part}°$(reset)$(ansi $forecast_color)/$(reset)$(ansi $(temp_color $min_part))${min_part}°$(reset)   $(ansi $dim_color)💧 ${rain_part}%  💨 ${wind_part} km/h (${knots} kn)$(reset)"
        forecast_row=$(( forecast_row + 1 ))
    done < <(read_forecast)

    # Right column ───────────────────────────────────────────────────────
    row=$top

    # Disk
    if [[ -n "$FREESPACE_VALUE" ]]; then
        put $row $right_col \
            "$(ansi $label_color)Disk    $(reset)$(ansi $(freespace_value_color))${FREESPACE_VALUE}$(reset)"
        row=$(( row + 1 ))
    fi

    # Wi-Fi
    if [[ -n "$WIFI_STATE" ]]; then
        wifi_extra=''
        [[ "$WIFI_STATE" != "disconnected" && -n "$WIFI_VALUE" ]] && wifi_extra=" (${WIFI_VALUE}%)"
        put $row $right_col \
            "$(ansi $label_color)Wi-Fi   $(reset)$(ansi $(wifi_value_color))$(wifi_bars)  ${WIFI_STATE}${wifi_extra}$(reset)"
        row=$(( row + 1 ))
    fi

    # Battery
    if [[ -n "$BATTERY_VALUE" ]]; then
        put $row $right_col \
            "$(ansi $label_color)Battery $(reset)$(ansi $(battery_value_color))${BATTERY_VALUE}%  ${BATTERY_STATE}$(reset)"
        row=$(( row + 1 ))
    fi

    # Network
    if [[ -n "$NETWORK_LABEL" ]]; then
        put $row $right_col \
            "$(ansi $label_color)Network $(reset)$(ansi $value_color)${NETWORK_LABEL}$(reset)"
        row=$(( row + 1 ))
    fi

    blank_stale_rows
    PREV_DIRTY_ROWS=("${DIRTY_ROWS[@]}")

    # Flush the entire frame in one write — no intermediate paints, no flicker.
    printf '%s' "$FRAME_BUFFER"
    # Park cursor in the bottom-left so it doesn't blink in the middle of content.
    move_to "$terminal_height" 1
}

# ── Main loop ───────────────────────────────────────────────────────────
# Hide the tmux statusbar while the dashboard owns this window. Save the
# previous value first — `status` can be on/off or a number of lines (e.g. 2
# in this config), so a blind `set -g status on` would collapse a 2-line bar.
prev_status=$(tmux show -gv status 2>/dev/null)
[[ -z "$prev_status" ]] && prev_status=on
tmux set -g status off 2>/dev/null

hide_cursor
clear_all
trap 'tmux set -g status "$prev_status" 2>/dev/null; show_cursor; clear_all; move_to 1 1' EXIT INT TERM

refresh_forecast_cache
read_widget_data

last_widget_refresh=$(date +%s)
last_forecast_refresh=$(date +%s)

while true; do
    now=$(date +%s)
    if (( now - last_widget_refresh >= widget_refresh_interval )); then
        read_widget_data
        last_widget_refresh=$now
    fi
    if (( now - last_forecast_refresh >= 60 )); then
        refresh_forecast_cache
        last_forecast_refresh=$now
    fi

    render

    # Wait 1s for a keypress; quit only on q or Esc.
    if read -t 1 -k 1 key 2>/dev/null; then
        if [[ "$key" == 'q' || "$key" == $'\033' ]]; then
            break
        fi
    fi
done
