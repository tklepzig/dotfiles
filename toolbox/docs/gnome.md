# Remove applications from gnome launcher

App launchers shown in GNOME Activities are located either in
`/usr/share/applications/` or `~/.local/share/applications/` as `.desktop`
files.

You can hide an individual app launcher from Activities by adding an extra
`NoDisplay=true` line to the corresponding .desktop file.

It is generally not advisable to edit the `.desktop` file located in
`/usr/share/applications/`. Instead copy the file to
`~/.local/share/applications/` first and make the change to the copied file.

# Fix non-working dark mode

Install `xdg-desktop-portal` and `xdg-desktop-portal-gnome`.

# Add listener for notifications

    dbus-monitor "interface='org.freedesktop.Notifications'"
