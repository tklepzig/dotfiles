# systemd

Day-to-day management of services and timers with `systemctl`, and reading logs
with `journalctl`.

Your own system units (and overrides) live in `/etc/systemd/system/`;
package-provided units in `/lib/systemd/system/` (don't hand-edit those).
**After editing a unit file, run `sudo systemctl daemon-reload`** or systemd
keeps using the old definition.

## Service lifecycle

```sh
sudo systemctl start myapp
sudo systemctl stop myapp          # does NOT trigger Restart=
sudo systemctl restart myapp
sudo systemctl reload myapp        # only if the unit defines ExecReload

sudo systemctl enable myapp        # start on boot
sudo systemctl disable myapp
sudo systemctl enable --now myapp  # enable AND start now

systemctl status myapp
systemctl is-active myapp          # active / inactive / failed
systemctl is-enabled myapp         # enabled / disabled
```

Main PID of a running service:

```sh
systemctl show -p MainPID --value myapp
```

## Inspecting & editing units

```sh
systemctl cat myapp                # effective unit file + any drop-ins
systemctl show myapp               # all resolved properties (verbose)
systemctl show -p Restart myapp    # a single property

sudo systemctl edit myapp          # create a drop-in override (override.conf)
sudo systemctl edit --full myapp   # edit a full shadowing copy of the unit
```

A drop-in lands at `/etc/systemd/system/myapp.service.d/override.conf` and only
overrides the keys you set, leaving the base unit intact — good for tweaking a
package unit without forking it.

## Logs (journalctl)

`-u` selects a unit; the flags compose.

```sh
journalctl -u myapp                # everything for the unit (pager)
journalctl -u myapp -f             # follow (tail -f)
journalctl -u myapp -e             # jump to the end
journalctl -u myapp -n 100         # last 100 lines
journalctl -u myapp --no-pager     # dump without the pager (scripts)

journalctl -u myapp --since today
journalctl -u myapp --since "1 hour ago"
journalctl -u myapp --since "2024-01-01 04:00" --until "2024-01-01 05:00"

journalctl -u myapp -b             # since the last boot
journalctl -u myapp -b -1          # the PREVIOUS boot (needs persistent logs, see below)
journalctl -u myapp -p err         # priority err and worse
journalctl -u myapp -o cat         # message text only, no metadata

journalctl -xeu myapp              # -x hints, -e end, -u unit: the "why did it die" go-to
journalctl --list-boots            # boot IDs for -b
```

Housekeeping:

```sh
journalctl --disk-usage
sudo journalctl --vacuum-time=7d   # drop entries older than 7 days
sudo journalctl --vacuum-size=200M
```

**Persistent logs.** Many systems (incl. Raspberry Pi OS) keep the journal
_volatile_ (`/run/log/journal`, wiped on reboot), so `-b -1` and "what happened
before the last reboot" come up empty. Make it persistent once:

```sh
# Option A: create the directory (journald auto-detects it on restart)
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal

# Option B: force it via config instead of relying on directory detection
# sudo sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# Either way:
sudo systemctl restart systemd-journald
```

Revert to volatile (logs wiped on reboot):

```sh
sudo rm -rf /var/log/journal
# if you used Option B, also undo the config change:
# sudo sed -i 's/^Storage=persistent/#Storage=auto/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```

## Timers (the cron replacement)

```sh
systemctl list-timers              # next/last fire for active timers
systemctl list-timers --all        # include inactive
systemctl status myapp.timer
systemctl cat myapp.timer          # see the OnCalendar etc.
```

A `.timer` triggers the `.service` of the **same name**. You enable the
**timer**, not the service it runs:

```sh
sudo systemctl enable --now myapp.timer
```

Run the underlying job _now_, without waiting for the schedule — just start the
service the timer points at:

```sh
sudo systemctl start myapp.service
```

Preview / validate an `OnCalendar` expression before trusting it:

```sh
systemd-analyze calendar "*-*-* 04:00:00"   # prints the normalized form + next elapse
```

`Persistent=true` (on the timer) runs a _missed_ job once the machine is back up
— right for a backup, usually wrong for something time-specific like a reboot.

Minimal pair — a daily 04:00 backup:

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Nightly backup
[Service]
Type=oneshot
ExecStart=/home/me/backup.sh
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily at 04:00
[Timer]
OnCalendar=*-*-* 04:00:00
Persistent=true
[Install]
WantedBy=timers.target
```

## Debugging a unit

```sh
systemctl status <unit>            # state, exit code, recent log lines
journalctl -xeu <unit>             # the full story with hints
systemctl --failed                 # everything currently failed
systemd-analyze verify ./my.service   # lint a unit file (typos, bad keys)
systemctl list-dependencies <unit> # what it waits on (After/Wants/Requires)
systemd-analyze blame              # slowest units at boot
```

`Restart=` behaviour (e.g. `Restart=on-failure`):

- non-zero exit, or death by a signal → restarted
- a clean `systemctl stop` → **not** restarted (intentional)
- an external `kill -9` (SIGKILL) → **restarted** (SIGKILL is never "clean"; a
  plain `kill`/SIGTERM can be treated as clean)
- a crash loop gets rate-limited: `start request repeated too quickly` (default
  5 starts / 10s)

```sh
systemctl reset-failed <unit>      # clear failed state / restart rate-limit
systemctl mask <unit>              # hard-disable (symlink to /dev/null)
systemctl unmask <unit>
```

## User vs system services

Everything above is **system** units (need `sudo`). systemd also runs
**per-user** units, managed without sudo:

```sh
systemctl --user start myapp
systemctl --user enable --now myapp
journalctl --user -u myapp
```

User unit files live in `~/.config/systemd/user/`. They normally only run while
you're logged in — to keep one running at boot without a login, enable
lingering:

```sh
sudo loginctl enable-linger <user>
```

Lingering also ensures `/run/user/<uid>` exists at boot, which a user service
needs for `XDG_RUNTIME_DIR` (e.g. to reach the session's PipeWire/PulseAudio
audio or D-Bus).
