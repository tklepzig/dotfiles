# Ruby → Python port

> **RESUME HERE (read this first).** Multi-week effort, done in small steps.
> - **Branch:** `port-to-python`.
> - **Current position:** Step 0 ✅ done. Step 1 **in progress** — sub-step 1
>   (golden-output harness) ✅ done.
> - **Next action:** Step 1, sub-step 2 — migrate `_info.yaml`→`_info.toml`
>   (mechanical), then port `_run.py` against `tomllib`, run
>   `toolbox/test/golden.py verify` to diff byte-identical, flip call sites.
>   The "Learn by Doing" piece for the port = the arg-validation logic in
>   `_run.py`.
> - **Working style:** one chunk at a time, keep each `.rb` until its `.py` is
>   verified, flip call sites late, delete `.rb` last. Hand Thomas a "Learn by
>   Doing" contribution per chunk (next: arg-validation logic in `_run.py`).
> - **Source of truth:** this file. Tick the checkboxes in `## Steps` as we go.

**Why:** `python3` is preinstalled on virtually every fresh system; `ruby` is not.
The install one-liner pipes the script *source* into the interpreter
(`ruby -e "$(curl …)"`), so it needs the interpreter to exist *before* anything
is installed. Porting `setup.rb` and `_run.rb` to Python removes the Ruby
prerequisite for bootstrapping a fresh machine.

**Approach:** small steps, ported chunk by chunk, `.rb` kept working until each
`.py` is verified, call sites flipped last, `.rb` deleted last.

## Decisions

- **Config format: TOML.** `_info.yaml` → `_info.toml` (and
  `info.additional.yaml` → `.toml`). Read with stdlib `tomllib` (Python 3.11+,
  read-only). Triple-quote `"""..."""` keeps multiline-help ergonomics; the
  nested structure maps cleanly (script → `[table]`, args → `[[array.of.tables]]`,
  completion → array). One-time mechanical migration (incl. downstream repos'
  `scripts/_info.yaml` and the README authoring docs).
- **Two interpreters, two floors:**
  - `setup.py` runs via `python3 -c "$(curl…)"` on the *fresh box's* python →
    **stdlib-only, low floor (3.8/3.9-safe), NO `tomllib`.**
  - `_run.py` runs *after* setup → may use `tomllib` (relies on the modern
    python setup guarantees).
- **Modern-python provisioning: conditional.** `setup.py` checks
  `sys.version_info`; if `>= (3, 11)` do nothing (Arch/modern Ubuntu); if older
  (e.g. stock macOS 3.9) provision a modern python via asdf. Do NOT fold the
  heavy `setup-asdf` (9 toolchains, incl. ruby) into bootstrap — a lean
  python-only ensure.
- **The one TOML leak in setup** = `link_scripts` merge (toolbox-includes path).
  Off the fresh-install path; runs *after* modern python is ensured → execute
  that merge under the modern interpreter so `setup.py`'s own imports stay
  stdlib-only. Needs a TOML *writer* (tomllib is read-only): ~15-line dumper or
  vendor single-file `tomli-w`. Step 8.
- **`_run.py` shebang** = `#!/usr/bin/env python3` (resolves through asdf shims
  once on PATH — same shell-reload requirement every toolbox alias already has).

## Key facts (so we don't re-derive them)

- **Golden harness:** `toolbox/test/golden.py` — `capture` (runs `_run.rb`,
  writes raw-byte snapshots + `manifest.json` to `toolbox/test/golden/`) and
  `verify [runner]` (diffs a candidate runner, default `_run.py`). Snapshots
  captured from `_run.rb` (20 cases incl. the `#{nil}`→`""` trailing-space
  cases). Lives *outside* `toolbox/scripts/` so `_run`'s glob doesn't list it.
  Two gotchas baked into the harness: (1) it runs the runner under a throwaway
  `$HOME` whose `.dotfiles` symlinks to the dev clone (so `SCRIPTS_PATH`
  resolves here, not the deployed `~/.dotfiles`); (2) that fake `$HOME` breaks
  the asdf `ruby`/`python3` shim (exits 126) unless `ASDF_DATA_DIR`/`ASDF_DIR`
  are pinned to the real `~/.asdf` — the harness does this.
- **`Dir.glob` is sorted in Ruby (since 3.0); Python `glob` is NOT.** `--list`
  and `--details` golden output is lexicographically sorted → `_run.py` must
  `sorted()` the globbed names or it breaks the byte-identical contract.


- **Bootstrap / call sites to flip (LAST):**
  - `README.md:9` install one-liner — `ruby -e "$(curl …setup.rb)"`
  - `README.md:14` install `--vim` variant
  - `zsh/alias:34` — `dotfiles-update` alias (same pattern)
  - `Dockerfile.test:19,21` — `ruby setup.rb --local [--vim]`
  - `Dockerfile.test-overrides:31` — `ruby setup.rb --local`
  - `README.md:94` uninstall — `./setup.rb --uninstall` (shebang)
- **`_run` stdout is a parsed contract** consumed by:
  - `toolbox/init.zsh` (`--list`, `--details`, `--completion`, dispatch)
  - `zsh/completion/_ws` (`--completion workspaces`)
  - `zsh/completion/_k` (`--completion git-worktree-list`)
  → output must stay byte-identical; golden-diff every mode.
- **`_run` is named in 3 places** on rename: `init.zsh`, its own self-exclusion
  list, and `setup.rb` `link_scripts` exclusion.
- **Fresh-install path never touches YAML** — `setup.rb`'s only YAML use
  (`link_scripts`) is behind the `~/.dotfiles-local/toolbox-include.yaml` guard,
  absent on a fresh box. So `setup.py` core can be pure stdlib.
- **`setup` mutates `$HOME`/`.zshrc`** — no clean golden-diff. Test in the
  existing Docker harness (`Dockerfile.test` + `test/overrides/run.sh`), never
  against the real `$HOME`.
- **The 4 vim `*.rb` files** (`vim/{vim,neovim}/{install,uninstall}.rb`) are
  `require`d into setup's scope (4–21 lines each). They become Python functions
  taking context (HOME, DF_PATH, helpers) — inline, no plugin system.

## Recurring learning fork

Per chunk: **shell-out vs native stdlib.** Pure file ops
(`find_override`, `merge`, `write_link`) → native Python (`os.symlink`,
read/append). External tools (`git`, `launchctl`, `systemctl`, `chsh`,
`brew`) stay `subprocess`.

## Steps

- [x] **0. Prep** — format decided (TOML); install-path Ruby checked
      (`set-theme` is zsh ✓; `notify` is ruby but a runtime toolbox dep, out of
      core scope); create a working branch.
- [ ] **1. `_run.rb` → `_run.py`** — migrate `_info.yaml`→`_info.toml`
      (mechanical script); port validator/dispatcher using stdlib `tomllib`;
      golden-diff all modes; flip `init.zsh` + `_ws` + `_k` to `_run.py`; keep
      `.rb` until verified.
- [ ] **2. setup skeleton** — `Logger`, `OS`, arg parsing (`--local/--vim/--uninstall`).
- [ ] **3. Program checks** — `program_installed?`, mandatory/optional/brew.
- [ ] **4. Link helpers** — `find_override`, `merge`, `write_link`,
      `add_link_with_override` (native file ops).
- [ ] **5. Repo clone/update** — git subprocess block.
- [ ] **6. `.zshrc` variant-export editing** — the regex insert/replace block.
- [ ] **7. Vim setup** — `setup_vim`/`cleanup_vim` + inline the 4 vim `*.rb`.
- [ ] **8. Config linking + python provisioning + toolbox-includes** —
      tmux/kitty/ranger/mpv/i3/aerospace + scheduler; conditional
      `ensure_asdf_python()` (only if system python < 3.11); toolbox-include
      TOML merge run under the modern interpreter (+ TOML writer).
- [ ] **9. Tail + cutover** — fzf, git, docker, default-shell, post-install;
      `uninstall`; flip README/alias/Dockerfiles; delete `.rb` files.

## Verification matrix

- `_run.py`: golden-diff vs `_run.rb` for `--list`, `--details`,
  `--completion help`, `--completion <script-with-completion>`,
  `help <script>`, `help <unknown>`, valid dispatch, missing-arg, too-many-args,
  unknown-script.
- `setup.py`: full run in `Dockerfile.test` (both `--local` and `--local --vim`)
  and `Dockerfile.test-overrides`; `test/overrides/run.sh` must pass.
