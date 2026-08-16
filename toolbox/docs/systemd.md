# systemd

Day-to-day management of services and timers with `systemctl`, and reading logs
with `journalctl`.

Your own system units (and overrides) live in `/etc/systemd/system/`;
package-provided units in `/lib/systemd/system/` (don't hand-edit those).
**After editing a unit file, run `sudo systemctl daemon-reload`** or systemd
keeps using the old definition.

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=Toolbox docs app
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/path/to/node /home/thomas/myapp/index.js
# If node (or whatever runner) is under asdf, you need to resolve the absolute path once
# and hardcode it:
#   asdf which node  ->  /home/thomas/.asdf/installs/nodejs/22.21.1/bin/node
Environment=SOME_ENV=blubb
WorkingDirectory=/home/thomas/myapp
Restart=on-failure
User=thomas

[Install]
WantedBy=multi-user.target
```

## Environment variables and secrets

Three mechanisms that look interchangeable and are not:

```ini
Environment=FOO=bar                       # inline, one key per line
EnvironmentFile=/home/thomas/app/.env     # systemd parses the file, then execs
EnvironmentFile=-/home/thomas/app/.env    # leading '-': a missing file is not an error
ExecStart=/path/node --env-file /home/thomas/app/.env /home/thomas/app/index.js
```

The first two are **systemd** reading the values — they show up in
`systemctl show -p Environment <unit>`. The last is the **app** reading the file
itself (node's own `--env-file`); systemd knows nothing about it, so
`systemctl show` is empty and the syntax rules are node's, not systemd's. Most
"why isn't my env var set" hunts are someone debugging the mechanism the unit
isn't using. `systemctl show -p Environment` tells you which one you're on in
one command.

systemd's `EnvironmentFile` parser is **not a shell**: no `$VAR` expansion, no
command substitution, no `export`. A value that works in `.bashrc` may not
survive.

**Secrets.** An env file holding tokens should be `chmod 600` and owned by the
unit's `User=`. A system unit's `EnvironmentFile` is read by PID 1 as root
*before* dropping to `User=`, so 600 costs nothing. Anything in `Environment=`
is world-readable via `systemctl show` — put secrets in a file, not inline.

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

**Persistent logs.** The default is `Storage=auto`: journald uses
`/var/log/journal` if that directory exists, else the _volatile_
`/run/log/journal` (a tmpfs, wiped on every reboot — so `-b -1` and "what
happened before the last reboot" come up empty).

So the folklore fix is "just `mkdir /var/log/journal` and restart journald".
**That is not always enough** — and on Raspberry Pi it silently does nothing.

⚠️ **The Raspberry Pi gotcha.** Pi OS / the Pi cloud images ship a vendor
drop-in `/usr/lib/systemd/journald.conf.d/40-rpi-volatile-storage.conf` that
sets `Storage=volatile`. With that in force, journald **ignores
`/var/log/journal` entirely** — the directory sits there empty forever and
`mkdir` accomplishes nothing. It also defeats editing the main
`/etc/systemd/journald.conf`, because **drop-ins always override the main config
file**, regardless of which one you edited.

Diagnose first — find anything forcing a `Storage=` and see where logs
_actually_ live:

```sh
grep -rs Storage /etc/systemd/journald.conf /etc/systemd/journald.conf.d \
  /run/systemd/journald.conf.d /usr/lib/systemd/journald.conf.d
find /run/log/journal /var/log/journal -name '*.journal'   # /run = volatile, /var/log = persistent
```

**Fix — beat the vendor drop-in with your own.** Don't edit the `/usr/lib` file
(it's package-owned, clobbered on upgrade). Drop-in files from all the
`journald.conf.d` dirs are merged **by filename in lexicographic order, last one
wins**, and `/etc` outranks `/usr/lib` — so a `99-` prefix sorts after the
vendor's `40-` and wins cleanly:

```sh
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/99-persistent-storage.conf >/dev/null <<'EOF'
[Journal]
Storage=persistent
EOF

sudo systemctl restart systemd-journald
sudo journalctl --flush          # migrate the volatile /run logs into /var/log
```

`Storage=persistent` makes journald **create** `/var/log/journal/<machine-id>/`
itself — no manual `mkdir` needed. Verify it adopted the dir:

```sh
ls -la /var/log/journal/                  # a <machine-id>/ subdir should now exist
find /var/log/journal -name '*.journal'   # journals now live here, not /run
```

The directory existing this boot isn't the goal — surviving a reboot is. The
real test:

```sh
sudo reboot
journalctl --list-boots          # should now show MORE THAN ONE boot
```

Revert to volatile (the image's default):

```sh
sudo rm /etc/systemd/journald.conf.d/99-persistent-storage.conf
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

## A unit that pushes to git (there is no ssh-agent)

A `Type=oneshot` backup ending in `git push git@github.com:…` runs from PID 1,
not from your login session, so **`SSH_AUTH_SOCK` is unset** — the agent you
unlocked when you ssh'd in does not exist for it. Symptoms: `Permission denied
(publickey)`, or the unit hanging until timeout on a passphrase prompt with
nowhere to go.

What it needs:

- A **passphrase-less** key. There's no interactive terminal to unlock one.
- The key named explicitly, so it doesn't depend on `~/.ssh/config` lookups that
  may resolve differently outside a login shell:

  ```ini
  Environment=GIT_SSH_COMMAND=ssh -i /home/thomas/.ssh/id_backup -o IdentitiesOnly=yes -o BatchMode=yes
  ```

  `BatchMode=yes` makes it fail fast instead of hanging on any prompt.
- The **host key already in `known_hosts`** for the unit's `User=`. A
  first-connection "authenticity of host … can't be established" prompt is a
  hang, not an error.

Test it the way systemd will run it, not the way your shell does:

```sh
sudo -u thomas env -i HOME=/home/thomas ssh -T git@github.com   # no agent, no session env
sudo systemctl start mybackup.service && journalctl -xeu mybackup.service
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
