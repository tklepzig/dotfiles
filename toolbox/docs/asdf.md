# asdf

These notes cover the **Go rewrite** of asdf (0.16+), which is what `setup-asdf`
installs (a self-contained prebuilt binary under `~/.asdf`). The CLI differs from
the old shell-based asdf: there is no `asdf local` / `asdf global` (use
`asdf set`), and `asdf update` no longer upgrades asdf itself.

asdf and the core toolchains (node, python, neovim, …) are provisioned by the
`setup-asdf` script — see `# setup-asdf` in the README. The commands below are
for day-to-day use afterwards.

Add a plugin (e.g. nodejs)

```
asdf plugin add nodejs
```

List installable versions

```
asdf list all nodejs
```

Show the latest available version

```
asdf latest nodejs
```

Install a specific version (this only installs it — it does **not** touch
`.tool-versions`)

```
asdf install nodejs 22.11.0
```

Record a version in `.tool-versions`. Without a flag this writes to the
`.tool-versions` in the current directory (project-local); `-u` writes to the one
in your home directory (the global default).

```
asdf set nodejs 22.11.0       # ./.tool-versions
asdf set -u nodejs 22.11.0    # ~/.tool-versions
```

Install the version(s) already pinned in `.tool-versions` (run with no tool name
to install everything listed)

```
asdf install nodejs
asdf install
```

Show the resolved versions for the current directory

```
asdf current
```

Reshim a plugin to create shims for newly added executables (e.g. after a
`pip install`)

```
asdf reshim python
```

Update the list of available versions for a plugin

```
asdf plugin update nodejs
asdf plugin update --all
```

Update asdf itself — `asdf update` is disabled in the Go rewrite. Re-run
`setup-asdf`, which downloads the latest asdf binary into `~/.asdf`.

```
setup-asdf
```
