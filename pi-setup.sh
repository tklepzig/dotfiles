#!/usr/bin/env bash
# pi-setup.sh — bootstrap a fresh Raspberry Pi 5 (SSH on) into a configured
# dev box that doubles as a headless server AND an i3 desktop.
# One script, no flags. Idempotent / safe to re-run.
#
# Invoke (post-merge, from master):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/tklepzig/dotfiles/master/pi-setup.sh)"
#
# i3 needs X11 (Bookworm defaults to Wayland) — see toolbox/docs/raspberrypi-os.md.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-tklepzig/dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-master}"
DF_PATH="$HOME/.dotfiles"

# Prime sudo once up front: prompts for the password a single time and caches it
# for the rest of the run. The `bash -c "$(curl ...)"` invocation form keeps
# stdin on the TTY so this prompt works — `curl ... | bash` would not.
sudo -v || { echo "ERROR: sudo access required." >&2; exit 1; }

# --- 1. apt packages ---------------------------------------------------------
sudo apt-get update

# Mandatory — all present in Bookworm:
#   shells/CLI setup.py wants · python build deps (asdf compiles python from
#   source on ARM; they also cover an opt-in `--ruby`) · mpv (media) ·
#   the i3 desktop (see below) · python3 (the bootstrap interpreter that runs
#   setup.py at step 2, before asdf exists).
# python3 ships preinstalled on Raspberry Pi OS, so this mostly just pins the
# dependency explicitly. setup.py is stdlib-only, so no venv/pip needed to run
# it; per-project dev venvs use the asdf python installed in step 4.
#
# The desktop set mirrors i3/install (the Arch package list), but three names
# differ on Debian and would 404 if copied verbatim from Arch:
#   dmenu                  -> suckless-tools       (dmenu is a virtual pkg here)
#   network-manager-applet -> network-manager-gnome (provides nm-applet)
#   ttf-font-awesome       -> fonts-font-awesome    (FA4 on Debian vs FA6 on Arch
#                                                     — cosmetic; configs emit no
#                                                     FA glyphs today)
# i3-dmenu-desktop isn't a separate pkg on Debian — it ships inside i3-wm (which
# the i3 metapackage pulls in). i3status/i3lock are listed explicitly rather
# than relied on as metapackage Recommends. fonts-jetbrains-mono is the bar /
# terminal font (i3/config) — installed manually on Arch, pinned here.
sudo apt-get install -y \
  git zsh tmux lynx ranger curl ca-certificates \
  build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libyaml-dev libffi-dev libtool \
  mpv \
  i3 kitty \
  suckless-tools rofi i3blocks i3status i3lock dunst picom feh \
  brightnessctl dex network-manager-gnome xss-lock playerctl \
  blueman arandr pavucontrol fonts-font-awesome fonts-jetbrains-mono \
  python3

# Best-effort: eza landed in Debian after the Bookworm freeze, so `apt install
# eza` may 404. Non-fatal — setup.py treats eza as optional anyway.
sudo apt-get install -y eza \
  || echo "NOTE: eza not available via apt (expected on Bookworm) — install via cargo/asdf later." >&2

# --- 2. dotfiles install -----------------------------------------------------
#
# Fetch to a var and verify it's non-empty FIRST: if the curl 404s (wrong
# branch, transient hiccup) the naive `python3 -c "$(curl ...)"` form would run
# an empty program — exit 0 under `set -e` — and silently skip provisioning.
installer="$(curl -fsSL "https://raw.githubusercontent.com/$DOTFILES_REPO/$DOTFILES_BRANCH/setup.py")"
if [ -z "$installer" ]; then
  echo "ERROR: failed to fetch setup.py from $DOTFILES_REPO@$DOTFILES_BRANCH." >&2
  exit 1
fi
DOTFILES_BRANCH="$DOTFILES_BRANCH" python3 -c "$installer"

# --- 3. enable linger --------------------------------------------------------
# Starts this user's systemd manager at boot so user services/timers run without
# an interactive login. On a headless Pi that's needed for the tmux-snapshot
# user timer (installed by setup.py) and for the XDG_RUNTIME_DIR (/run/user/
# <uid>) that per-user PipeWire audio relies on. Idempotent.
#
# Audio output itself (picking the USB DAC as the default PipeWire sink) is
# hardware-specific and left manual — see toolbox/docs/raspberrypi-os.md.
sudo loginctl enable-linger "$(whoami)"

# --- 4. asdf + languages (LAST: slowest + most fragile) ----------------------
bash "$DF_PATH/toolbox/scripts/setup-asdf" --minimal

echo
echo "pi-setup complete. setup.py already set zsh as the login shell — log out and"
echo "back in (or 'exec zsh') to load everything."
echo "Audio (USB DAC) is set up manually — see toolbox/docs/raspberrypi-os.md."
