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
# Pull the active theme's palette (written by `set-theme`) so the clock and
# widget accent track whatever theme is set. Falls back to borg-ish defaults.
[[ -f "$HOME/.dotfiles/colours.zsh" ]] && source "$HOME/.dotfiles/colours.zsh"

clock_color=${primaryText:-28}    # theme primaryText
date_color=252
weather_color=220
forecast_color=252
label_color=${accentText:-64}     # widget labels — theme accent
value_color=252
warning_color=214
critical_color=196
accent_color=${accentText:-64}    # e.g. battery charging
dim_color=240

ansi()  { printf '\033[38;5;%sm' "$1"; }
bgansi(){ printf '\033[48;5;%sm' "$1"; }
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

# ── Layout ──────────────────────────────────────────────────────────────
wide_breakpoint=110    # cols ≥ this → 3-column layout; below → centered stack
band_max=160           # cap content-band width so panels flank the clock on
                       # ultra-wide screens instead of drifting to the edges

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

# Rain probability → 256-color code.
rain_color() {
    local pct="$1"
    [[ -z "$pct" || ! "$pct" =~ ^[0-9]+$ ]] && { printf '%s' "$dim_color"; return; }
    if   (( pct < 20 )); then printf '%s' "$dim_color"
    elif (( pct < 50 )); then printf '39'    # blue / light rain possible
    elif (( pct < 80 )); then printf '%s' "$warning_color"
    else                      printf '%s' "$critical_color"
    fi
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

# ── Display width (platform-independent emoji handling) ─────────────────
# wcwidth disagrees across macOS and glibc and undercounts VS16 symbols
# (☀️ ☁️ ⛈️), so we measure width from a known glyph set rather than the
# platform's wcwidth: every emoji below renders as 2 cells on any
# emoji-capable terminal, on both macOS and Arch.
typeset -ga WIDE_GLYPHS=(☀ ☁ ⛅ ⛈ 🌫 🌦 🌧 🌨 💧 💨)

disp_width() {
    setopt local_options extendedglob
    local string glyph before
    string=${(S)1//$'\033'\[[0-9;]#[a-zA-Z]/}   # strip CSI escapes (color/cursor)
    string=${string//$'️'/}                # variation selector-16 (zero width)
    local -i width=0
    for glyph in "${WIDE_GLYPHS[@]}"; do
        before=${#string}
        string=${string//$glyph/}
        width+=$(( (before - ${#string}) * 2 ))
    done
    width+=${#string}
    print -r -- $width
}

# Starting column (1-based) to center a `width`-cell string on the terminal
# axis — which is the same axis the clock is centered on.
center_col() {
    local -i col=$(( (term_cols - $1) / 2 + 1 ))
    (( col < 1 )) && col=1
    print -r -- $col
}

# ── Widget data readers (raw scripts emit `state\nvalue`) ───────────────
BATTERY_STATE=''  BATTERY_VALUE=''
FREESPACE_STATE='' FREESPACE_VALUE=''
WIFI_STATE=''     WIFI_VALUE=''
NETWORK_LABEL=''
MEDIA_STATE=''    MEDIA_TITLE=''

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

    # Now-playing — same reader the statusbar uses (emits state\ntitle; exits
    # silently when nothing is playing). Executed directly like the other
    # readers (media-info.*.zsh carry the exec bit).
    MEDIA_STATE=''; MEDIA_TITLE=''
    if [[ -f "$HOME/.dotfiles/tmux/media-info.$OS.zsh" ]]; then
        local mout
        mout=$("$HOME/.dotfiles/tmux/media-info.$OS.zsh" 2>/dev/null)
        MEDIA_STATE=$(sed -n 1p <<< "$mout")
        MEDIA_TITLE=$(sed -n 2p <<< "$mout")
    fi
}

# Now-playing state → icon (matches the statusbar's media-info.zsh).
media_icon() {
    case "$MEDIA_STATE" in
        Playing) printf '▶' ;;
        Paused)  printf '⏸' ;;
        Stopped) printf '⏹' ;;
        *)       printf '♪' ;;
    esac
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

# ── Clock font — exact tmux 5×5 pixel grid (window-clock.c) ─────────────
# X = lit pixel (rendered as a bg-colored space), space = unlit.
# Using bg color avoids █ width ambiguity and matches tmux clock rendering.
DIGIT=(
    "XXXXX|X...X|X...X|X...X|XXXXX"   # 0
    "....X|....X|....X|....X|....X"   # 1
    "XXXXX|....X|XXXXX|X....|XXXXX"   # 2
    "XXXXX|....X|XXXXX|....X|XXXXX"   # 3
    "X...X|X...X|XXXXX|....X|....X"   # 4
    "XXXXX|X....|XXXXX|....X|XXXXX"   # 5
    "XXXXX|X....|XXXXX|X...X|XXXXX"   # 6
    "XXXXX|....X|....X|....X|....X"   # 7
    "XXXXX|X...X|XXXXX|X...X|XXXXX"   # 8
    "XXXXX|X...X|XXXXX|....X|XXXXX"   # 9
)
COLON_DIGIT=".....|..X..|.....|..X..|....."
clock_height=5

# ── Cursor / screen control ─────────────────────────────────────────────
move_to()     { printf '\033[%d;%dH' "$1" "$2"; }   # row, col (1-based)
clear_to_eol(){ printf '\033[K'; }
clear_all()   { printf '\033[2J'; }
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

# ── Terminal dimensions (refreshed on resize) ───────────────────────────
# A plain read-loop script doesn't reliably see $COLUMNS/$LINES update on
# resize, so we read the live size from the tty and refresh it on SIGWINCH.
typeset -gi term_cols=80 term_rows=24
typeset -g prev_term_cols='' prev_term_rows=''
update_dims() {
    local size
    size=$(stty size 2>/dev/null < /dev/tty)
    if [[ "$size" == <->" "<-> ]]; then
        term_rows=${size%% *}
        term_cols=${size##* }
    else
        term_rows=${LINES:-24}
        term_cols=${COLUMNS:-80}
    fi
}
TRAPWINCH() { update_dims; }

# Track rows we've written so we can clear them between frames.
typeset -ga DIRTY_ROWS=()
typeset -ga PREV_DIRTY_ROWS=()

# Buffer a positioned write at (row, col). No clear-to-EOL here: with multiple
# columns sharing a row (weather | clock | system), an EOL clear from one
# element would wipe its neighbours. Whole rows are cleared up-front instead —
# see the clear_prefix in render().
FRAME_BUFFER=''
put() {
    local row=$1 col=$2 text=$3
    FRAME_BUFFER+=$'\033['"${row};${col}"'H'"${text}"
    DIRTY_ROWS+=("$row")
}

# Render one 5-char bitmap row as a terminal string using run-length bg color.
# Adjacent lit pixels share one bgansi..reset span — no seams between them.
# Result stored in PIXEL_ROW_RESULT to avoid subshell overhead.
PIXEL_ROW_RESULT=''
CLK_BG_ON=''
CLK_BG_RST=''
pixel_row() {
    local bitmap=$1 in_on char result
    in_on=0
    result=''
    for char in "${(s::)bitmap}"; do
        if [[ $char == X ]]; then
            (( in_on )) || { result+="$CLK_BG_ON"; in_on=1; }
            result+=' '
        else
            (( in_on )) && { result+="$CLK_BG_RST"; in_on=0; }
            result+=' '
        fi
    done
    (( in_on )) && result+="$CLK_BG_RST"
    PIXEL_ROW_RESULT="$result"
}

# Render clock at (start_row, start_col) into FRAME_BUFFER.
# Font: exact tmux window-clock.c 5×5 grid, 1 cell per pixel, 6-col spacing.
render_clock() {
    local start_row=$1 start_col=$2
    local hour minute row_idx row colon_bitmap
    local -a h1_rows h2_rows m1_rows m2_rows colon_rows
    local col_h1 col_h2 col_colon col_m1 col_m2
    local h1_r h2_r m1_r m2_r col_r

    hour=$(date '+%H')
    minute=$(date '+%M')

    col_h1=$start_col
    col_h2=$(( start_col + 6 ))
    col_colon=$(( start_col + 12 ))
    col_m1=$(( start_col + 18 ))
    col_m2=$(( start_col + 24 ))

    CLK_BG_ON="$(bgansi $clock_color)"
    CLK_BG_RST="$(reset)"

    h1_rows=("${(s:|:)DIGIT[$((${hour[1]}  + 1))]}")
    h2_rows=("${(s:|:)DIGIT[$((${hour[2]}  + 1))]}")
    m1_rows=("${(s:|:)DIGIT[$((${minute[1]} + 1))]}")
    m2_rows=("${(s:|:)DIGIT[$((${minute[2]} + 1))]}")
    colon_rows=("${(s:|:)COLON_DIGIT}")

    for row_idx in 1 2 3 4 5; do
        row=$(( start_row + row_idx - 1 ))

        pixel_row "${h1_rows[$row_idx]}"; h1_r="$PIXEL_ROW_RESULT"
        pixel_row "${h2_rows[$row_idx]}"; h2_r="$PIXEL_ROW_RESULT"
        pixel_row "${m1_rows[$row_idx]}"; m1_r="$PIXEL_ROW_RESULT"
        pixel_row "${m2_rows[$row_idx]}"; m2_r="$PIXEL_ROW_RESULT"

        # Colon is always lit — no blinking.
        pixel_row "${colon_rows[$row_idx]}"
        col_r="$PIXEL_ROW_RESULT"

        put $row $col_h1 "$h1_r"
        put $row $col_h2 "$h2_r"
        put $row $col_colon "$col_r"
        put $row $col_m1 "$m1_r"
        put $row $col_m2 "$m2_r"
    done
}

# ── Render ──────────────────────────────────────────────────────────────
# Clock is always centered (tmux clock-mode: x = COLS/2-15, y = LINES/2-3).
# Everything else arranges around it, responsive to terminal width:
#
#   Wide  (COLS ≥ wide_breakpoint): 3 columns inside a centered, width-capped
#         band — weather left of the clock, system widgets right of it (both
#         vertically aligned to the clock band), date + forecast centered below.
#   Narrow: a single centered vertical stack — clock, date, weather, forecast,
#         and a centered system status strip pinned to the bottom edge.
render() {
    # NOTE: declare all locals at function top. zsh prints `var=value` if
    # `local` appears inside a loop body followed by an assignment.
    local terminal_width terminal_height clock_left top mode
    local date_str date_colored current rest line wline fl clear_prefix
    local cur_code cur_temp cur_feels cur_humidity cur_wind cur_icon knots
    local date_part max_part min_part code_part rain_part wind_part icon day_label
    local wifi_extra top_cell bot_cell forecast_top_line forecast_bot_line
    local media_title media_line
    local -i media_budget
    local -a weather_lines system_lines forecast_top forecast_bot forecast_cw all_rows
    local -i band_width band_left band_right wstart sstart frow col clear_row
    local -i idx cell_w pad_top pad_bot top_w bot_w forecast_total_w forecast_col

    terminal_width=$term_cols
    terminal_height=$term_rows

    clock_left=$(( terminal_width / 2 - 15 ))
    (( clock_left < 2 )) && clock_left=2
    top=$(( terminal_height / 2 - 3 ))
    (( top < 1 )) && top=1

    if (( terminal_width >= wide_breakpoint )); then
        mode=wide
    else
        mode=narrow
    fi

    FRAME_BUFFER=''
    DIRTY_ROWS=()
    # On any resize, repaint from a clean slate (still one buffered write → no
    # flicker). Otherwise partial-width rows from the previous size can linger,
    # and crossing the breakpoint would leave stranded content from both modes.
    if [[ "$terminal_width" != "$prev_term_cols" || "$terminal_height" != "$prev_term_rows" ]]; then
        FRAME_BUFFER+=$'\033[2J'
        PREV_DIRTY_ROWS=()
    fi

    render_clock $top $clock_left

    date_str=$(date '+%A, %-d %B %Y')
    date_colored="$(ansi $date_color)${date_str}$(reset)"

    # ── Current-weather lines (each individually colored) ─────────────────
    weather_lines=()
    current=$(read_weather_current)
    if [[ -n "$current" ]]; then
        cur_code="${current%%|*}";  rest="${current#*|}"
        cur_temp="${rest%%|*}";     rest="${rest#*|}"
        cur_feels="${rest%%|*}";    rest="${rest#*|}"
        cur_humidity="${rest%%|*}"; cur_wind="${rest#*|}"
        cur_icon=$(emoji_for_code "$cur_code")
        knots=$(kmh_to_knots "$cur_wind")
        weather_lines+=("${cur_icon}$(ansi $(temp_color $cur_temp))${cur_temp}°C$(reset)")
        weather_lines+=("$(ansi $value_color)💧 ${cur_humidity}%$(reset)")
        weather_lines+=("$(ansi $value_color)💨 ${cur_wind} km/h (${knots} kn)$(reset)")
    fi

    # ── Forecast: two stacked lines per day ───────────────────────────────
    # Top:    "Day  icon  max°/min°"
    # Bottom: "💧 rain%  💨 wind km/h"
    # Each day becomes a fixed-width cell (the wider of its two lines) so the
    # rain/wind line sits directly under the matching day card.
    forecast_top=(); forecast_bot=(); forecast_cw=()
    while IFS= read -r fl; do
        [[ -z "$fl" ]] && continue
        date_part="${fl%%|*}";  rest="${fl#*|}"
        max_part="${rest%%|*}";  rest="${rest#*|}"
        min_part="${rest%%|*}";  rest="${rest#*|}"
        code_part="${rest%%|*}"; rest="${rest#*|}"
        rain_part="${rest%%|*}"; wind_part="${rest#*|}"
        icon=$(emoji_for_code "$code_part")
        day_label=$(date -j -f "%Y-%m-%d" "$date_part" "+%a" 2>/dev/null \
            || date -d "$date_part" "+%a" 2>/dev/null \
            || echo "$date_part")
        knots=$(kmh_to_knots "$wind_part")
        top_cell="$(ansi $forecast_color)${day_label}$(reset) ${icon}$(ansi $(temp_color $max_part))${max_part}°$(reset)$(ansi $forecast_color)/$(reset)$(ansi $(temp_color $min_part))${min_part}°$(reset)"
        bot_cell="$(ansi $value_color)💧 ${rain_part}%  💨 ${wind_part} km/h (${knots} kn)$(reset)"
        top_w=$(disp_width "$top_cell")
        bot_w=$(disp_width "$bot_cell")
        forecast_top+=("$top_cell")
        forecast_bot+=("$bot_cell")
        (( top_w >= bot_w )) && forecast_cw+=($top_w) || forecast_cw+=($bot_w)
    done < <(read_forecast)

    # Assemble the two centered rows (mode-independent — modes just pick the
    # row offsets). Each cell is right-padded to its column width so both rows
    # share one geometry and the block centers as a unit.
    forecast_top_line=''; forecast_bot_line=''; forecast_total_w=0
    if (( ${#forecast_top} )); then
        for idx in {1..${#forecast_top}}; do
            cell_w=${forecast_cw[$idx]}
            pad_top=$(( cell_w - $(disp_width "${forecast_top[$idx]}") ))
            pad_bot=$(( cell_w - $(disp_width "${forecast_bot[$idx]}") ))
            forecast_top_line+="${forecast_top[$idx]}${(l:$pad_top:)}"
            forecast_bot_line+="${forecast_bot[$idx]}${(l:$pad_bot:)}"
            forecast_total_w+=$cell_w
            if (( idx < ${#forecast_top} )); then
                forecast_top_line+="    "; forecast_bot_line+="    "
                forecast_total_w+=4
            fi
        done
        forecast_col=$(center_col $forecast_total_w)
    fi

    # ── System-widget lines ───────────────────────────────────────────────
    system_lines=()
    if [[ -n "$FREESPACE_VALUE" ]]; then
        system_lines+=("$(ansi $label_color)Disk $(reset)$(ansi $(freespace_value_color))${FREESPACE_VALUE}$(reset)")
    fi
    if [[ -n "$WIFI_STATE" ]]; then
        wifi_extra=''
        [[ "$WIFI_STATE" != "disconnected" && -n "$WIFI_VALUE" ]] && wifi_extra=" ${WIFI_VALUE}%"
        system_lines+=("$(ansi $label_color)Wi-Fi $(reset)$(ansi $(wifi_value_color))$(wifi_bars)${wifi_extra}$(reset)")
    fi
    if [[ -n "$BATTERY_VALUE" ]]; then
        system_lines+=("$(ansi $label_color)Bat $(reset)$(ansi $(battery_value_color))${BATTERY_VALUE}% ${BATTERY_STATE}$(reset)")
    fi
    if [[ -n "$NETWORK_LABEL" ]]; then
        system_lines+=("$(ansi $label_color)Net $(reset)$(ansi $value_color)${NETWORK_LABEL}$(reset)")
    fi

    if [[ "$mode" == wide ]]; then
        # Content band: capped width, centered — keeps panels flanking the
        # clock instead of drifting to the far edges on an ultra-wide screen.
        band_width=$(( terminal_width - 4 ))
        (( band_width > band_max )) && band_width=$band_max
        band_left=$(( (terminal_width - band_width) / 2 + 1 ))
        band_right=$(( band_left + band_width - 1 ))

        # Weather — left-aligned at the band edge, centered in the clock band.
        if (( ${#weather_lines} )); then
            wstart=$(( top + (clock_height - ${#weather_lines}) / 2 ))
            (( wstart < top )) && wstart=$top
            frow=$wstart
            for line in "${weather_lines[@]}"; do
                put $frow $band_left "$line"
                frow+=1
            done
        fi

        # System — right-aligned to the band edge, centered in the clock band.
        if (( ${#system_lines} )); then
            sstart=$(( top + (clock_height - ${#system_lines}) / 2 ))
            (( sstart < top )) && sstart=$top
            frow=$sstart
            for line in "${system_lines[@]}"; do
                col=$(( band_right - $(disp_width "$line") + 1 ))
                (( col < 1 )) && col=1
                put $frow $col "$line"
                frow+=1
            done
        fi

        # Date — centered directly under the clock.
        put $(( top + clock_height + 1 )) $(center_col $(disp_width "$date_colored")) "$date_colored"

        # Forecast — two centered rows (day/temp, then rain/wind) under the date.
        if (( ${#forecast_top} )); then
            put $(( top + clock_height + 3 )) $forecast_col "$forecast_top_line"
            put $(( top + clock_height + 4 )) $forecast_col "$forecast_bot_line"
        fi

        # Now-playing — centered under the forecast, truncated to the band.
        if [[ -n "$MEDIA_TITLE" ]]; then
            media_budget=$(( band_width - 2 ))
            (( ${#MEDIA_TITLE} > media_budget )) \
                && media_title="${MEDIA_TITLE[1,media_budget-1]}…" \
                || media_title="$MEDIA_TITLE"
            media_line="$(ansi $value_color)$(media_icon) ${media_title}$(reset)"
            put $(( top + clock_height + 6 )) $(center_col $(disp_width "$media_line")) "$media_line"
        fi
    else
        # Narrow — centered vertical stack.
        put $(( top + clock_height + 1 )) $(center_col $(disp_width "$date_colored")) "$date_colored"

        if (( ${#weather_lines} )); then
            wline="${(j:   :)weather_lines}"
            put $(( top + clock_height + 2 )) $(center_col $(disp_width "$wline")) "$wline"
        fi

        if (( ${#forecast_top} )); then
            put $(( top + clock_height + 4 )) $forecast_col "$forecast_top_line"
            put $(( top + clock_height + 5 )) $forecast_col "$forecast_bot_line"
        fi

        # Now-playing — centered below the forecast.
        if [[ -n "$MEDIA_TITLE" ]]; then
            media_budget=$(( terminal_width - 4 ))
            (( ${#MEDIA_TITLE} > media_budget )) \
                && media_title="${MEDIA_TITLE[1,media_budget-1]}…" \
                || media_title="$MEDIA_TITLE"
            media_line="$(ansi $value_color)$(media_icon) ${media_title}$(reset)"
            put $(( top + clock_height + 7 )) $(center_col $(disp_width "$media_line")) "$media_line"
        fi

        # System widgets — centered status strip at the bottom edge.
        if (( ${#system_lines} )); then
            line="${(j: · :)system_lines}"
            put $(( terminal_height - 2 )) $(center_col $(disp_width "$line")) "$line"
        fi
    fi

    # Clear every row touched this frame and last frame BEFORE painting, then
    # lay down the positioned content. This replaces per-element clear-to-EOL
    # (which wiped column neighbours) and also blanks rows that vanished since
    # the last frame. Emitted as one prefix → still a single flicker-free write.
    all_rows=("${DIRTY_ROWS[@]}" "${PREV_DIRTY_ROWS[@]}")
    clear_prefix=''
    for clear_row in ${(nou)all_rows}; do
        clear_prefix+=$'\033['"${clear_row};1"'H'$'\033[2K'
    done
    PREV_DIRTY_ROWS=("${DIRTY_ROWS[@]}")
    prev_term_cols=$terminal_width
    prev_term_rows=$terminal_height

    # Flush the entire frame in one write — no intermediate paints, no flicker.
    printf '%s%s' "$clear_prefix" "$FRAME_BUFFER"
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

update_dims
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
