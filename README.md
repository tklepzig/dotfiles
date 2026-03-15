# dotfiles

My dotfiles.

## Installation

### Neovim profile (default)

    /usr/bin/env ruby -e "$(curl -Ls https://raw.githubusercontent.com/\
    tklepzig/dotfiles/master/setup.rb)"

### Vim profile

    /usr/bin/env ruby -e "$(curl -Ls https://raw.githubusercontent.com/\
    tklepzig/dotfiles/master/setup.rb)" -- --vim

## Migration from basic/full variants to vim/neovim

The vim/neovim setup was restructured. If you are upgrading from the previous
version (where the variants were called `basic` and `full`), follow the steps
below before re-running `setup.rb`.

### Renamed directories

| Before       | After         |
| ------------ | ------------- |
| `vim/basic/` | `vim/vim/`    |
| `vim/full/`  | `vim/neovim/` |

Any override files in those directories must be moved accordingly:

| Before                           | After                          |
| -------------------------------- | ------------------------------ |
| `vim/basic/vimrc.override`       | `vim/vim/vimrc.override`       |
| `vim/full/vimrc.override`        | `vim/neovim/vimrc.override`    |
| `vim/basic/plugins.override.vim` | `vim/vim/plugins.override.vim` |

### Neovim plugin overrides (vim-plug → lazy.nvim)

The neovim profile now uses **lazy.nvim** instead of vim-plug. If you had
`vim/full/plugins.override.vim`, convert it to lazy.nvim format and save it as
`vim/nvim-lazy-plugins.override.lua`:

```vim
" Before (vim/full/plugins.override.vim)
-Plug 'some/plugin'
Plug 'my-org/my-plugin'
```

```lua
-- After (vim/nvim-lazy-plugins.override.lua)
return {
  { "some/plugin", enabled = false },
  { "my-org/my-plugin" },
}
```

### Local user plugins for neovim

`~/.dotfiles-local/plugins.vim` is still used for the **vim** profile. For the
**neovim** profile, create `~/.dotfiles-local/lazy-plugins.lua` instead:

```lua
return {
  { "my-org/my-plugin" },
}
```

### DOTFILES_VARIANT environment variable

The variant names changed. Update the value in your `~/.zshrc` if you have it
set explicitly:

| Before           | After              |
| ---------------- | ------------------ |
| `full` (default) | `neovim` (default) |
| `basic`          | `vim`              |

### Local config files (`.vimrc`, `.tmux.conf`)

`setup.rb` only ever appends source lines to local config files — it never
removes old ones. After upgrading, stale lines pointing to the old paths will
remain and cause errors on startup:

| File           | Stale lines to remove                                        |
| -------------- | ------------------------------------------------------------ |
| `~/.vimrc`     | `source .../vim/basic/vimrc`, `source .../vim/full/vimrc`    |
| `~/.tmux.conf` | `source .../colours.zsh` (tmux now uses `colours.tmux.conf`) |

The easiest way to clean all of this up in one step is to uninstall first, which
removes all dotfiles source lines from local config files while leaving any
manual customisations intact:

    cd ~/.dotfiles && ./setup.rb --uninstall

### Re-run setup

Then pull the new version and re-run setup using the `dotfiles-update` alias:

    dotfiles-update

## Setup asdf

See `# setup-asdf`.

## Themes

See `# set-theme`.

## Overrides

There are two levels of overrides: **repo-level** (committed alongside the
dotfiles, e.g. in a downstream repo that extends these dotfiles for a specific
team or project) and **user-level** (local machine only, never committed).

### General mechanism

For most config files, placing an override file next to the base file is enough.
Two naming conventions are supported:

- `<file>.override` — e.g. `zsh/zshrc.override`
- `<name>.override.<ext>` — e.g. `zsh/zshrc.override.zsh`

`setup.rb` detects the override file automatically and sources/includes it after
the base file in the relevant dotfile.

The following sections list all files that support this mechanism.

### zsh

| Base file   | Override file        |
| ----------- | -------------------- |
| `zsh/zshrc` | `zsh/zshrc.override` |

### tmux

| Base file              | Override file                   |
| ---------------------- | ------------------------------- |
| `tmux/tmux.conf`       | `tmux/tmux.conf.override`       |
| `tmux/vars.linux.conf` | `tmux/vars.linux.conf.override` |
| `tmux/vars.osx.conf`   | `tmux/vars.osx.conf.override`   |

### kitty

| Base file                | Override file                     |
| ------------------------ | --------------------------------- |
| `kitty/kitty.conf`       | `kitty/kitty.conf.override`       |
| `kitty/kitty.theme.conf` | `kitty/kitty.theme.conf.override` |

### i3

| Base file   | Override file        |
| ----------- | -------------------- |
| `i3/config` | `i3/config.override` |

### vim

| Base file          | Override file               |
| ------------------ | --------------------------- |
| `vim/vim/vimrc`    | `vim/vim/vimrc.override`    |
| `vim/neovim/vimrc` | `vim/neovim/vimrc.override` |

### Plugins — vim profile (vim-plug)

Create `vim/vim/plugins.override.vim`. Lines prefixed with `-` remove the
matching line from the base; all other lines are appended:

```vim
-Plug 'neoclide/coc.nvim'    " remove a plugin
Plug 'my-org/my-plugin'      " add a plugin
```

`setup.rb` merges this into `vim/vim/plugins.vim` at setup time.

### Plugins — neovim profile (lazy.nvim)

Create `vim/nvim-lazy-plugins.override.lua` returning a list of lazy.nvim specs.
It is loaded at neovim startup and merged with the base plugin list. To disable
a plugin use `enabled = false`; lazy.nvim merges specs for the same plugin, with
the override taking precedence:

```lua
return {
  { "neoclide/coc.nvim", enabled = false },  -- disable a plugin
  { "my-org/my-plugin" },                    -- add a plugin
}
```

### User-level local overrides (`~/.dotfiles-local/`)

For changes that should only apply to one machine and not be committed:

| What              | File                                                                      |
| ----------------- | ------------------------------------------------------------------------- |
| vim plugins       | `~/.dotfiles-local/plugins.vim` (vim-plug format, sourced at startup)     |
| neovim plugins    | `~/.dotfiles-local/lazy-plugins.lua` (lazy.nvim specs, loaded at startup) |
| post-install hook | `~/.dotfiles-local/post-install` (shell script, run by `setup.rb`)        |

## Toolbox

The toolbox is a script management system exposed via the `#` command. Scripts
live in `toolbox/scripts/` and are invoked as `# <script-name> [args]` with
shell completion.

### Adding scripts

1. Create an executable file in `toolbox/scripts/your-script-name` with a
   shebang line:

   ```bash
   #!/usr/bin/env bash
   echo "hello"
   ```

2. Register it in `toolbox/scripts/_info.yaml` (or in
   `toolbox/scripts/info.additional.yaml` to avoid touching the base file):

   ```yaml
   your-script-name:
     help: Brief description shown in completion
     args:
       - name: input file # required argument
       - name: output format # required argument
         optional: true
         default: json # used when argument is omitted
     completion: # optional: static completion candidates
       - option-a
       - option-b
   ```

   The `args` list defines both validation (setup.rb rejects calls with wrong
   arity) and the completion hints shown in the shell.

### info.additional.yaml

`toolbox/scripts/info.additional.yaml` is an optional file that gets merged with
`_info.yaml` at runtime. Use it in downstream repos or overrides to add script
metadata without modifying the base file:

```yaml
my-extra-script:
  help: Does something project-specific
  args:
    - name: target
```

### Toolbox includes

To pull in scripts and docs from an external directory or repository, create
`~/.dotfiles-local/toolbox-include.yaml` listing paths to include:

```yaml
- /absolute/path/to/extra-toolbox
- relative/path/from/dotfiles-local # resolved relative to ~/.dotfiles-local
```

Each listed path may be a plain directory or a git repository. If it contains a
`.git` directory, `setup.rb` will run `git fetch && git merge` on it
automatically during installation to keep it up to date.

The directory is expected to follow this layout (both subdirectories are
optional):

```
extra-toolbox/
  scripts/       # executables + optional _info.yaml
  docs/          # markdown files linked into the toolbox docs
```

## Testing

### Build and run the neovim profile (default)

    docker build -f Dockerfile.test -t dotfiles-test .
    docker run -it dotfiles-test

> To clean up afterwards:
>
>     docker rm $(docker ps -a -q --filter ancestor=dotfiles-test) 2>/dev/null; docker rmi dotfiles-test

### Build and run the vim profile

    docker build -f Dockerfile.test --build-arg VARIANT=vim -t dotfiles-test-vim .
    docker run -it dotfiles-test-vim

> To clean up afterwards:
>
>     docker rm $(docker ps -a -q --filter ancestor=dotfiles-test-vim) 2>/dev/null; docker rmi dotfiles-test-vim

Inside the container you land in a fully configured zsh session. For the neovim
profile, lazy.nvim bootstraps and installs plugins on the first `nvim` launch —
this is expected and mirrors the behaviour on a real machine.

### Test override functionality

    docker build -f Dockerfile.test-overrides -t dotfiles-test-overrides .

The build places fixture override files for every supported override mechanism,
runs setup, then executes `test/overrides/run.sh` automatically. The build fails
if any test fails. The tested mechanisms are:

- `vim/vim/vimrc.override` — wired into `~/.vimrc` by setup.rb (grep check)
- `vim/neovim/vimrc.override` — applied at runtime (headless nvim check)
- `vim/vim/plugins.override.vim` — plugin removed from merged plugins.vim (grep
  check)
- `vim/nvim-lazy-plugins.override.lua` — loaded at neovim startup (headless nvim
  check)
- `~/.dotfiles-local/plugins.vim` — wired into `~/.vimrc` and not overwritten
  (grep checks)
- `~/.dotfiles-local/lazy-plugins.lua` — loaded at neovim startup (headless nvim
  check)

> To clean up afterwards:
>
>     docker rm $(docker ps -a -q --filter ancestor=dotfiles-test-overrides) 2>/dev/null; docker rmi dotfiles-test-overrides
