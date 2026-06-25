# Ruby → Python port

> **RESUME HERE (read this first).** Multi-week effort, done in small steps.
> - **Branch:** `port-to-python`.
> - **Current position:** Step 0–7 ✅. **Step 8a + 8b done** ✅ — `install()`
>   now runs `setup_theme_and_colours()` → `setup_vim()` → zshrc link →
>   `configure_bc()` → `configure_ruby()`, then hits the NotImplementedError
>   stub (8c next). All functional-tested + 9 unit tests green. See Step 8
>   sub-chunks below for what's next. Older Step 7 detail retained:
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
> - **Next action:** Step 10 Ruby removal DONE ✅ (coexistence cut short by
>   Thomas — single Python path, git history is the record). Deleted `setup.rb`,
>   `_run.rb`, `_info.yaml`, the 4 vim `*.rb` routines; dropped the `.rb`/`.yaml`
>   entries from `_run.py`'s exclusion list; stripped the README "Legacy Ruby
>   installer" + toolbox-include `.yaml`-fallback notes; flipped prose
>   `setup.rb`→`setup.py`; fixed stale `setup.rb` comments in the test harness.
>   (`golden.py` was already removed in the "Clean up" commit; `info.additional.yaml`
>   never existed.) **The whole installer + runner are ported, Python is the only
>   path** (Steps 0–10 ✅). This branch is ready to merge.
>   NOT done (deliberately out of scope — separate cleanup commit): the deferred
>   install() reorg & the kitty/i3 `add_link_with_override` mkdir gap.
> - **Step 8c DONE** ✅ — toolbox includes ported. Decision **superseded**: the
>   vendored `tomli-w` writer was removed in favour of a **read-time merge** — no
>   TOML is written at all (see `## Decisions`). `toolbox/setup_includes.py`
>   (modern-python helper: reads `toolbox-include.toml` `paths=[]`, git fetch/merge
>   each repo, `link_docs`/`link_scripts`; validates each include `_info.toml` with
>   `tomllib` then symlinks it into `scripts/info.d/NN-<name>.toml`; rebuilds
>   `info.d/` each run so dropped includes un-register; exit 2 = soft-skipped).
>   `_run.py` globs `info.d/*.toml` (sorted; `NN-` prefix = list order, later wins)
>   and merges them before `info.additional.toml`. setup.py:
>   `resolve_modern_python()` (fast-path `sys.executable` if
>   ≥3.11; PATH search else None — search/None branch UNVERIFIED on this Arch box;
>   finds an existing modern python, does NOT provision via asdf despite the
>   original plan wording)
>   + `add_toolbox_includes()` (guard → delegate to helper under modern python)
>   wired into install() after `configure_ruby` (Ruby order, setup.rb:350–354).
>   Verified: converter round-trips dict-equal to hand-authored `_info.toml` (41
>   entries); `test/setup_includes_test.py` (5 tests: subprocess happy-path
>   symlinks+merge+include-wins, no-op, Plan-B no-writer + dump-error both leave
>   core `_info.toml` intact, expand_include_path); golden still 21/21;
>   setup_test.py still 9/9. README authoring docs flipped to TOML for the
>   RUNNER-tied bits only (core `_info.toml`, `info.additional.toml`); the
>   INSTALLER-tied `toolbox-include` section stays YAML until Step 9 cutover
>   (active `setup.rb` still reads `.yaml`).
>   <details><summary>older Step 8c scouting (kept)</summary>
>   SCOUT FIRST: grep for
>   `_info.yaml` readers — porting these forces the YAML→TOML format migration
>   (stdlib has no YAML reader) of `_info.yaml` + `toolbox-include.yaml`, plus a
>   TOML *writer* (tomllib is read-only), plus re-exec under modern python.
>   Split the format migration (8c-pre, validate vs `golden.py`) from the new
>   toolbox logic — two independent failure modes. `ensure_asdf_python()` lands
>   here too (no-op on this Arch box; don't mark its provision path verified).
>   Then 8d (remaining config blocks). See the Step 8 sub-chunk checklist below.
>   </details>
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
- **DECISION RESOLVED (8c) — eliminate the merge write entirely.** First shipped
  as a vendored `tomli-w` writer; later removed. There is now **no structured
  write in the whole port** — instead of merging include `_info.toml`s into the
  core file at setup time, each is symlinked into `scripts/info.d/` and `_run.py`
  merges them at read time (the trick it already used for `info.additional.toml`).
  This drops `_vendor/tomli_w`, the writer-import fallback dance, and the
  side effect of leaving the deployed clone's committed `_info.toml` git-dirty.
  Setup-time `tomllib` validation of each include preserves the soft-skip so a
  bad include can't poison `_run.py` at runtime. Original options, for the record:
  1. **Vendor `tomli-w`** (single MIT file, v1.2.0, pure-python, 0 deps, py3.9+)
     — LEANING THIS + a soft-skip fallback (Plan B). 0 LOC written, spec-correct,
     `_info` stays TOML, touches nothing verified, `_run.py` untouched. Merge =
     `tomllib.load` → `{**base, **inc}` → atomic-write `tomli_w.dumps`.
     **Plan B (vendor import/dump fails for any reason):** import vendored under
     a distinct name (`_vendor/`) first, fall back to a pip-installed `tomli_w`;
     if neither resolves, log the exact `<modern-python> -m pip install tomli-w`
     command, **soft-skip only the merge** (do all other setup), and `exit 1` so
     re-running setup completes it (setup.py is already idempotent → re-run IS
     the resume, no state machine). Safe because: the whole include path is
     behind the `~/.dotfiles-local/toolbox-include.yaml` guard (fresh box never
     hits it), include scripts still get symlinked (plain `ln`, no TOML) so they
     *work* — only their help/args/completion metadata is pending. Atomic write
     (serialize-to-string then replace) is mandatory regardless, so a mid-dump
     crash can't truncate the real `_info.toml`.
  2. **Hand-rolled dumper** — ~22 LOC happy-path for this exact shape (help
     str / `args` array-of-tables / `completion` str-array), ~45–55 LOC robust.
     Rejected reason isn't LOC, it's escaping corners (`'''` inside help,
     `"`/`\\` in basic strings) → malformed TOML crashes `_run.py`'s tomllib on
     the include path, found late.
  3. **JSON `_info` + a manage-script** — most disruptive: re-migrate files,
     flip `_run.py` reader tomllib→json, re-golden all 21 modes, downstream
     repos' authoring workflow changes. The manage-script only earns its keep
     IF we switch to JSON (TOML stays hand-editable). Defer it to a nice-to-have.
  Thomas deferred the pick (2026-06-24, "in a few hours"). Resolve before
  writing 8c code.
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
      - [x] **8b** — zshrc link (`add_link_with_override`, kept AFTER
            `setup_vim` per Ruby's actual order; "move before vim" TODO left as
            a comment, NOT enacted) + `configure_bc()` (writes `scale=2\n` only
            if `.bc` absent) + `configure_ruby()` (`force_symlink` for
            default-gems + rubocop.yml). Functional-tested, 9 unit tests green.
      - [x] **8c** — toolbox includes DONE. Vendor `tomli-w` + soft-skip Plan B;
            `toolbox/setup_includes.py` modern-python helper; JS converter;
            `resolve_modern_python` + `add_toolbox_includes` in setup.py. 8c-pre
            format migration turned out near-empty (Step 1 already did `_info`;
            only `toolbox-include` needed a format, chosen TOML). Verified:
            converter round-trip dict-equal (41), 5 include tests, golden 21/21,
            setup_test 9/9. See the RESUME-HERE 8c block for detail.
      - [x] **8d** — remaining config blocks DONE. **8d-1**: `sync_vim_plugins`
            (headless Lazy!/coc or vim-plug, stdin=DEVNULL), `configure_tmux` +
            `install_tmux_snapshot_scheduler` (launchd on mac [UNVERIFIED] /
            systemd user timer on linux). **8d-2**: `configure_kitty/ranger/mpv/
            i3/aerospace`, all behind `program_installed`/mac gates. Verified:
            6 new tests in `setup_test.py` (gated app-config link creation +
            no-op, sync_vim_plugins command shape, scheduler-linux unit links —
            all under temp HOME + mocked subprocess so the real ~/.config and
            systemctl are untouched; kitty/ranger/mpv/i3 ARE installed on the dev
            box). NB: every 8d-2 block is gated, so the Linux Docker harness
            skips them — faithfulness > CI here. FAITHFUL QUIRK kept: Ruby does
            NOT mkdir ~/.config/kitty or ~/.config/i3 before `add_link_with_
            override` (only i3blocks/dunst/picom/ranger/mpv get mkdir) → assumes
            those dirs exist; see Step 9 cleanup.
      - **8a–8d verified end-to-end (2026-06-24)** via a Docker smoke: built the
        `Dockerfile.test` base (archlinux + deps) WITHOUT the `setup.rb` RUN, then
        `docker run … python3 /root/.dotfiles/setup.py --local`. install() ran
        faithfully through every block (checks → bc/ruby → toolbox guard → vim
        plugin sync → tmux + systemd scheduler → ranger; kitty/mpv/i3 correctly
        gate-skipped) and stopped exactly at the Step-9 `NotImplementedError`. No
        unexpected crash. (Container-only noise: `systemctl --user` warns "systemd
        not running" — harmless, faithful, exit ignored.)
      - Conditional `resolve_modern_python()` (only if system python < 3.11)
        landed in 8c. Its search/None branch CANNOT be exercised on this Arch box
        (3.14 ≥ 3.11 → fast path); don't mark it "verified" here. NB: it finds an
        existing modern python, it does not provision one via asdf.
- [x] **9. Tail + cutover to Python-default — DONE.** install() tail
      (fzf/git/docker/chsh/post-install/"Setup done.") + `uninstall()`
      (`remove_links` + teardown) ported (commit 843dd52). Cutover (commit
      87b7cc4): README install one-liners + `--vim` + uninstall, `dotfiles-update`
      alias, both Dockerfiles → `python3 … setup.py`; setup.py +x; Ruby kept as a
      documented fallback (README "Legacy Ruby installer" section); toolbox-include
      README → `.toml` with `.yaml`-fallback note. Fallback mechanism = **docs-only**
      (Thomas's call) — no env toggle. **VERIFIED via the official harness (now on
      setup.py):** `Dockerfile.test` neovim built ("Setup done."), `--vim` built,
      `Dockerfile.test-overrides` built + `run.sh` **7 passed / 0 failed** (vimrc/
      plugin/lazy overrides exercised at real vim+nvim runtime). setup_test 19/19,
      includes 8/8, golden 21/21. Ruby files (`setup.rb`,`_run.rb`,`_info.yaml`,
      `info.additional.yaml`) intentionally RETAINED — removal is Step 10.
      <details><summary>cutover strategy detail (kept)</summary>
      **CUTOVER STRATEGY (Thomas, 2026-06-24): do NOT delete the `.rb`/`.yaml`
      at cutover.** Merge this branch with the Python path as the *default* but
      Ruby retained as a *fallback* that co-exists for ~some months, so a
      real-world problem with the Python installer/runner can be worked around
      by reverting to Ruby. Ruby deletion is a separate later step (Step 10),
      after Python has proven itself in the wild.
      - **Tail:** port the rest of `install()` — fzf clone+install, `git/install`,
        docker completion (curl), default-shell (`chsh`), `~/.dotfiles-local/
        post-install` script, "Setup done." Then port `uninstall()`.
      - **Cutover (flip call sites to default Python, keep Ruby runnable):**
        README install one-liner + `--vim` variant, `zsh/alias` `dotfiles-update`,
        `Dockerfile.test`/`-overrides`, README uninstall → all point at
        `setup.py`/`_run.py`. `setup.rb`/`_run.rb` stay in the tree, runnable.
        **DESIGN TBD:** the fallback switch — likely a documented manual
        `ruby setup.rb` escape hatch + (for the runner) an env toggle
        (e.g. `DOTFILES_RUNNER=ruby` in `init.zsh`) defaulting to Python. Decide
        when implementing.
      - **Golden STAYS a Ruby↔Python differ during coexistence** — do NOT
        repoint `capture` yet; it keeps proving the Python path matches Ruby
        while both ship. Golden embeds live data (theme lists, script names, help
        text), so a legitimate data change breaks it (jupiter-2 did): "golden
        failed" after adding e.g. a theme = "re-capture needed", not a regression.
      - **`toolbox-include` coexistence wrinkle:** Python default reads
        `toolbox-include.toml`, Ruby fallback reads `toolbox-include.yaml`. An
        includes user who falls back to Ruby needs the `.yaml` too. Document both
        during coexistence (keep the README section dual, or note the caveat);
        the full flip to `.toml`-only happens at Step 10. The runner-tied
        authoring docs (core `_info.toml`, `info.additional.toml`) were already
        flipped in 8c.
      </details>
      - **Resolved at implementation:** fallback switch = docs-only (no env
        toggle); the `toolbox-include` README was flipped to `.toml` now with a
        `.yaml`-fallback note (not left dual); golden stays a differ as planned.
- [x] **10. Ruby removal (coexistence cut short — single Python path now).** DONE.
      - Deleted `setup.rb`, `_run.rb`, `_info.yaml`, the 4 vim `*.rb` routines.
        (`golden.py` already gone via "Clean up"; `info.additional.yaml` never existed.)
      - Dropped `_info.yaml`/`_run.rb`/`info.additional.yaml` from `_run.py`'s
        exclusion list (kept `_info.toml`/`info.additional.toml`/`info.d`/`_run.py`).
      - README: removed "Legacy Ruby installer (fallback)" section + toolbox-include
        `.yaml`-fallback note; flipped prose `setup.rb`→`setup.py`. Test-harness
        stale `setup.rb` comments fixed.
      - **STILL OPEN (split to a separate cleanup commit, NOT part of removal):**
      - **`add_link_with_override` mkdir gap:** kitty + i3-main assume their
        `~/.config/X` dir exists (Ruby never mkdir'd them; ported faithfully in
        8d-2). Add the mkdir here.
      - **Deferred `install()` reorganization (ONE pass).** setup.rb carried 5
        sibling org-only TODOs (commit bbcd11e "Some todos", 2025-04-06): clean
        up / split into smaller chunks (skip heavy steps for the basic variant);
        group the vim-related links into the vim block; move the `zsh/zshrc` link
        up with the other linking (verified behaviourally a no-op — `setup_vim`
        never sources `~/.zshrc`); group all `add_link_with_override` linking into
        one block. We dropped the stale comments from `setup.py` while porting
        (keeping Ruby's order); the regrouping is intentional cleanup to do once,
        now that the line-by-line port is verified.

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
