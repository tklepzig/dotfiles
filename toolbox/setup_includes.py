#!/usr/bin/env python3
"""Toolbox-include processor.

Runs ONLY under a python >= 3.11 — setup.py's `add_toolbox_includes` resolves a
modern interpreter (`resolve_modern_python`) and invokes this as a subprocess. It
reads `~/.dotfiles-local/toolbox-include.toml`, updates each included repo, links
its `docs/`+`scripts/`, and registers its `scripts/_info.toml` for the toolbox
runner by symlinking it into `scripts/info.d/`.

It lives outside setup.py on purpose: it needs `tomllib` (>= 3.11) to read the
include list and validate each include's `_info.toml`, while setup.py must stay
stdlib-only / low-floor so it can run on a fresh box's old python.

No TOML is written. Instead of merging every include's `_info.toml` into the core
file — which needed a TOML *writer* and left the deployed clone's committed
`_info.toml` git-dirty — each include's `_info.toml` is symlinked into
`scripts/info.d/NN-<name>.toml`, and `_run.py` globs + merges them at read time
(the same trick it already uses for `info.additional.toml`). The `NN-` prefix is
the include's position in the list, so the sorted glob preserves "later include
wins".

Note: dropping an include un-registers its metadata (info.d is rebuilt each run)
but leaves its script symlinks in `scripts/`; those orphans need manual cleanup.

Exit codes: 0 = ok; 2 = an include was soft-skipped (bad data) so setup.py can
tell the user a re-run will finish it.
"""
import os
import shutil
import subprocess
import sys
import tomllib

HOME = os.environ["HOME"]
DF_PATH = f"{HOME}/.dotfiles"
DF_LOCAL_PATH = f"{HOME}/.dotfiles-local"
SCRIPTS_DIR = os.path.join(DF_PATH, "toolbox", "scripts")
INFO_D = os.path.join(SCRIPTS_DIR, "info.d")

EXIT_INCLUDE_SKIPPED = 2


def log(message, indent=0):
    print(f"{'  ' * indent}{message}")


def symlink_force(source, target):
    # `ln -sf`: drop any existing target (incl. broken link), then symlink.
    if os.path.islink(target) or os.path.exists(target):
        os.remove(target)
    os.symlink(source, target)


def link_dir(source_dir, dest_dir, skip=()):
    """Symlink each entry of source_dir into dest_dir. Skips names in `skip` and
    dotfiles (matching Ruby's `Dir.glob('*')`, which ignores hidden files).
    Returns False when source_dir is absent."""
    if not os.path.isdir(source_dir):
        return False
    for name in sorted(os.listdir(source_dir)):
        if name.startswith(".") or name in skip:
            continue
        symlink_force(os.path.join(source_dir, name), os.path.join(dest_dir, name))
    return True


def link_docs(path):
    if link_dir(os.path.join(path, "docs"), os.path.join(DF_PATH, "toolbox", "docs")):
        log("Linking docs", 1)


def link_scripts(path, slot_index):
    """Symlink the include's scripts (except its `_info.toml`) and register that
    `_info.toml` for the runner by symlinking it into `info.d/NN-<name>.toml`.
    Returns True if the include was soft-skipped (its `_info.toml` won't parse)."""
    scripts_dir = os.path.join(path, "scripts")
    if link_dir(scripts_dir, SCRIPTS_DIR, skip=("_info.toml",)):
        log("Linking scripts", 1)

    include_info = os.path.join(scripts_dir, "_info.toml")
    if not os.path.isfile(include_info):
        return False

    # Validate here, under tomllib, so a malformed include surfaces at setup with
    # a re-run hint — rather than at runtime in _run.py, where one bad include's
    # _info.toml would break *every* toolbox command.
    try:
        with open(include_info, "rb") as include_file:
            tomllib.load(include_file)
    except tomllib.TOMLDecodeError as error:
        log(f"Could not parse {include_info}: {error!r}", 1)
        log("Fix the include _info.toml, then re-run setup.", 1)
        return True

    log("Registering _info.toml", 1)
    os.makedirs(INFO_D, exist_ok=True)
    # 3-digit pad so the lexical sort in _run.py stays == list order even past
    # 99 includes ("100" would sort before "99" at a 2-digit pad).
    slot = os.path.join(INFO_D, f"{slot_index:03d}-{os.path.basename(path)}.toml")
    symlink_force(include_info, slot)
    return False


def expand_include_path(raw_path):
    # Mirror Ruby's File.expand_path(raw_path, DF_LOCAL_PATH): ~ expands, an
    # absolute path stays, a relative one resolves against DF_LOCAL_PATH.
    expanded = os.path.expanduser(raw_path)
    if not os.path.isabs(expanded):
        expanded = os.path.join(DF_LOCAL_PATH, expanded)
    return os.path.abspath(expanded)


def update_include_repo(path):
    # Non-interactive git: a real install is unattended, so a non-fast-forward
    # merge must not open $EDITOR and a private remote must not block on a
    # credential prompt. Ruby's backticks inherited stdin and had neither guard.
    log("Found git repo, updating", 1)
    git_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    fetched = subprocess.run(
        ["git", "fetch"], cwd=path, env=git_env,
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    if fetched.returncode == 0:  # Ruby's `git fetch && git merge`
        subprocess.run(
            ["git", "merge", "--no-edit"], cwd=path, env=git_env,
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


def process_includes():
    include_list = os.path.join(DF_LOCAL_PATH, "toolbox-include.toml")
    if not os.path.isfile(include_list):
        # No list at all = no includes intended, so drop any slots a previous
        # run left behind. (A *corrupt* or non-list `paths` below is different —
        # those keep the last-good info.d so a typo mid-edit can't wipe working
        # metadata.)
        shutil.rmtree(INFO_D, ignore_errors=True)
        return 0
    try:
        with open(include_list, "rb") as list_file:
            paths = tomllib.load(list_file).get("paths", [])
    except tomllib.TOMLDecodeError as error:
        log(f"Could not parse {include_list}: {error!r}")
        log("Fix the include list, then re-run setup.")
        return EXIT_INCLUDE_SKIPPED
    if not isinstance(paths, list):
        # A bare string would otherwise iterate character-by-character below.
        log(f"`paths` in {include_list} must be an array of strings.")
        return EXIT_INCLUDE_SKIPPED

    # Rebuild info.d from scratch each run so an include dropped from the list
    # stops being merged by _run.py (the old in-place rewrite never un-merged).
    shutil.rmtree(INFO_D, ignore_errors=True)

    any_skipped = False
    for slot_index, raw_path in enumerate(paths):
        # Isolate each entry: one malformed list element (non-string), a flaky
        # git repo, or a bad include _info.toml must not sink the others. Ruby
        # let one bad entry abort the loop; we soft-skip it and carry on. The
        # expand + isdir checks live inside the try too, since a non-string
        # entry raises in expand_include_path. The slot_index is the list
        # position, so info.d/ sorts in list order (later include wins).
        try:
            path = expand_include_path(raw_path)
            if not os.path.isdir(path):
                continue
            log(raw_path)
            if os.path.isdir(os.path.join(path, ".git")):
                update_include_repo(path)
            link_docs(path)
            if link_scripts(path, slot_index):
                any_skipped = True
        except Exception as error:
            log(f"Skipped {raw_path!r} — {error!r}", 1)
            log("Fix this include, then re-run setup.", 1)
            any_skipped = True

    return EXIT_INCLUDE_SKIPPED if any_skipped else 0


if __name__ == "__main__":
    sys.exit(process_includes())
