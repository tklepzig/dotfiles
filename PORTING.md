# Ruby → Python port

> **RESUME HERE (read this first).** Multi-week effort, done in small steps.
> - **Branch:** `port-to-python`.
> - **Current position:** Step 0–7 ✅. **Step 8a done** ✅ —
>   `setup_theme_and_colours()` (theme/`set-theme`, 3 `colours.*` links,
>   byte-identical default `plugins.vim`, `vim/plugins.vim` link) now runs
>   BEFORE `setup_vim()` in `install()`. Functional-tested + 9 unit tests green.
>   See Step 8 sub-chunks below for what's next. Older Step 7 detail retained:
>   **Step 7** — vim setup ported:
>   `link_vim_plugins` (override merge + the `"pluginfile` sed, done natively),
>   `setup_vim(variant)`, `cleanup_vim()`. DECISION CHANGE (Thomas): the 4 vim
>   `*.rb` files were NOT inlined — they became standalone `*.py` files
>   (`vim/{vim,neovim}/{install,uninstall}.py`) so the routines stay easy to edit
>   in isolation. Contract: each exposes `run(context)`; `context` =
>   SimpleNamespace(home, df_path, check_optional_installation). setup.py loads
>   them by absolute path from DF_PATH via importlib (Ruby `require` analog —
>   setup.py is curl-piped, can't static-import). Routines use stdlib directly
>   (os/pathlib/shutil) — `ln -sf`→remove+symlink, `rm -f`→unlink(missing_ok),
>   `rm -rf`→rmtree(ignore_errors). All 4 routines functional-tested through the
>   loader (dirs, 6 symlinks, force re-run, removals, missing-file no-op). `.rb`
>   kept until Step 9. setup_vim() wired into install() but placed AFTER the
>   zshrc edit — Step 8 config-linking lines must be inserted BEFORE it.
> - **Next action:** Step 8b — zshrc link + `.bc` + ruby default-gems/rubocop
>   links (setup.rb:336–352). Port Ruby's ACTUAL order: the zshrc link runs
>   AFTER `setup_vim`; leave the "TODO: move before vim" as a comment, do NOT
>   enact it (faithfulness — a TODO is a behaviour change in cleanup costume).
>   Then 8c (toolbox + TOML writer + ensure_asdf_python) and 8d (config blocks).
>   See the Step 8 sub-chunk checklist below for the full breakdown + the 8c
>   scout-`_info.yaml`-first warning.
> - **Working style:** one chunk at a time, keep each `.rb` until its `.py` is
>   verified, flip call sites late, delete `.rb` last. Hand Thomas a "Learn by
>   Doing" contribution per chunk (Step 2 was full-write-then-review by choice).
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
  `require`d into setup's scope (4–21 lines each). PORTED (Step 7) as standalone
  `*.py` files (NOT inlined — Thomas's call, so they stay editable in isolation):
  each exposes `run(context)` and is loaded by absolute path from DF_PATH via
  importlib. `context` = SimpleNamespace(home, df_path,
  check_optional_installation). `.rb` deleted in Step 9.

## Recurring learning fork

Per chunk: **shell-out vs native stdlib.** Pure file ops
(`find_override`, `merge`, `write_link`) → native Python (`os.symlink`,
read/append). External tools (`git`, `launchctl`, `systemctl`, `chsh`,
`brew`) stay `subprocess`.

## Steps

- [x] **0. Prep** — format decided (TOML); install-path Ruby checked
      (`set-theme` is zsh ✓; `notify` is ruby but a runtime toolbox dep, out of
      core scope); create a working branch.
- [x] **1. `_run.rb` → `_run.py`** — migrated `_info.yaml`→`_info.toml`
      (JSON-equal); ported validator/dispatcher on stdlib `tomllib`;
      golden-diff all 21 modes byte-identical; flipped `init.zsh` + `_ws` + `_k`
      to `_run.py`. `.rb`/`.yaml` kept until Step 9.
- [x] **2. setup skeleton** — `Logger`, `OS`, arg parsing (`--local/--vim/--uninstall`).
- [x] **3. Program checks** — `program_installed` (stdlib `shutil.which`),
      mandatory/optional/brew. Smoke-tested.
- [x] **4. Link helpers** — `find_override`, `merge`, `write_link`,
      `add_link_with_override` (native file ops). Functional-tested.
- [x] **5. Repo clone/update** — git subprocess block (list-form, `cwd=`,
      `DEVNULL`, hash capture; conditional `-b` clone). + install() preamble.
- [x] **6. `.zshrc` variant-export editing** — `update_zshrc_variant`;
      replace/insert/append, 4 cases tested; re.MULTILINE + re.escape traps.
- [x] **7. Vim setup** — `setup_vim`/`cleanup_vim`/`link_vim_plugins`; 4 vim
      `*.rb` → standalone `*.py` (`run(context)`), loaded via importlib by path.
- [ ] **8. Config linking + python provisioning + toolbox-includes** — sliced
      into 4 sub-chunks:
      - [x] **8a** — pre-vim config links + reorder: `setup_theme_and_colours()`
            (mkdir DF_LOCAL, `set-theme` via subprocess [status ignored, matches
            backticks], 3 `colours.*` links, byte-identical default
            `plugins.vim` [no trailing newline, idempotent], `vim/plugins.vim`
            link), called BEFORE `setup_vim()`. Functional-tested.
      - [ ] **8b** — zshrc link + `.bc` + ruby default-gems/rubocop links. NOTE:
            port Ruby's actual order (zshrc link runs AFTER `setup_vim`); leave
            the "TODO: move before vim" as a comment, do NOT enact it.
      - [ ] **8c** — toolbox: `link_scripts`/`add_toolbox_includes`/`link_docs`.
            Forces the YAML→TOML format migration of `_info.yaml` +
            `toolbox-include.yaml` (stdlib has no YAML reader) + a TOML *writer*
            (tomllib is read-only) + re-exec under modern python. SCOUT FIRST:
            grep for `_info.yaml` readers — migrating its format can break the
            golden byte-contract, so split the format migration (8c-pre,
            validate vs `golden.py`) from the new toolbox logic.
      - [ ] **8d** — remaining config blocks: tmux scheduler (launchd/systemd),
            kitty/ranger/mpv/i3/aerospace, behind `program_installed` gates.
      - Conditional `ensure_asdf_python()` (only if system python < 3.11) lands
        in 8c. Its provision branch CANNOT be exercised on this Arch box
        (3.14 ≥ 3.11 → no-op); don't mark the provision path "verified" here.
- [ ] **9. Tail + cutover** — fzf, git, docker, default-shell, post-install;
      `uninstall`; flip README/alias/Dockerfiles; delete `.rb` files.
      - On deleting `_run.rb`: repoint `golden.py` `capture`'s default runner
        from `_run.rb` to `_run.py` (self-snapshot) — capture breaks otherwise.
        The harness then becomes a plain regression test, not a Ruby↔Python
        differ. Also drop `_info.yaml`/`info.additional.yaml` from both runners'
        exclusion lists once the YAML files are gone.
      - Golden embeds live data (theme lists, script names, help text), so any
        legitimate data change breaks it (jupiter-2 did). "golden failed" after
        adding e.g. a theme = "re-capture needed", not a regression.

## Verification matrix

- `_run.py`: golden-diff vs `_run.rb` for `--list`, `--details`,
  `--completion help`, `--completion <script-with-completion>`,
  `help <script>`, `help <unknown>`, valid dispatch, missing-arg, too-many-args,
  unknown-script.
- `setup.py`: full run in `Dockerfile.test` (both `--local` and `--local --vim`)
  and `Dockerfile.test-overrides`; `test/overrides/run.sh` must pass. PLUS
  `test/setup_test.py` — stdlib unittest over the pure-logic helpers
  (`find_override`, `update_zshrc_variant`, `merge`) covering the regex branches
  the Docker run never hits. Run: `python3 test/setup_test.py`. `force_symlink`
  is the single shared `ln -sf` helper (in setup.py, passed via
  `vim_routine_context`) — reuse it for every ported `ln -sf` in Step 8.
