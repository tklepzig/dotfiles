#!/usr/bin/env python3
"""Toolbox-include processor.

Runs ONLY under a python >= 3.11 — setup.py's `add_toolbox_includes` resolves a
modern interpreter (`resolve_modern_python`) and invokes this as a subprocess. It
reads `~/.dotfiles-local/toolbox-include.toml`, updates each included repo, links
its `docs/`+`scripts/`, and merges its `scripts/_info.toml` into the core
toolbox `_info.toml`.

It lives outside setup.py on purpose: the merge needs `tomllib` (>= 3.11) plus a
TOML *writer*, while setup.py must stay stdlib-only / low-floor so it can run on
a fresh box's old python. Here, imports are free to use tomllib + the vendored
`tomli_w`.

Exit codes: 0 = ok; 2 = a merge was soft-skipped (no writer / data error) so
setup.py can tell the user a re-run will finish it.
"""
import os
import subprocess
import sys
import tomllib

HOME = os.environ["HOME"]
DF_PATH = f"{HOME}/.dotfiles"
DF_LOCAL_PATH = f"{HOME}/.dotfiles-local"
CORE_INFO = os.path.join(DF_PATH, "toolbox", "scripts", "_info.toml")

EXIT_MERGE_SKIPPED = 2


def load_toml_writer():
    """Vendored `tomli_w` first, else a pip-installed copy, else None (Plan B).

    The except is deliberately broad: a corrupt/truncated vendored file raises
    `SyntaxError`, not `ImportError`, and we still want to fall through to the
    pip copy rather than crash the whole include step.
    """
    vendor = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_vendor")
    sys.path.insert(0, vendor)
    try:
        import tomli_w

        return tomli_w
    except Exception:
        if vendor in sys.path:
            sys.path.remove(vendor)
        sys.modules.pop("tomli_w", None)  # drop the half-failed vendored import
        try:
            import tomli_w

            return tomli_w
        except Exception:
            return None


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


def link_scripts(path, toml_writer):
    """Symlink the include's scripts (except its `_info.toml`) and merge that
    `_info.toml` into the core one. Returns True if the merge was soft-skipped."""
    scripts_dir = os.path.join(path, "scripts")
    dest_scripts = os.path.join(DF_PATH, "toolbox", "scripts")
    if link_dir(scripts_dir, dest_scripts, skip=("_info.toml",)):
        log("Linking scripts", 1)

    include_info = os.path.join(scripts_dir, "_info.toml")
    if not os.path.isfile(include_info):
        return False

    log("Merging _info.toml", 1)
    with open(CORE_INFO, "rb") as core_file:
        merged = tomllib.load(core_file)
    with open(include_info, "rb") as include_file:
        merged.update(tomllib.load(include_file))  # include wins, mirrors Ruby's merge

    if toml_writer is None:
        log("No TOML writer available — skipping this merge.", 1)
        log("Run `<this-python> -m pip install tomli-w`, then re-run setup.", 1)
        return True

    # Serialize fully BEFORE touching the file, then replace atomically — a
    # failure (corrupt writer, or data with no TOML representation) leaves the
    # real _info.toml intact. pip can't fix a data error, so print the actual
    # cause rather than imply "install + re-run" always works.
    try:
        text = toml_writer.dumps(merged)
    except Exception as error:
        log(f"Could not serialize merged _info.toml: {error!r}", 1)
        log("Fix the offending include _info entry, then re-run setup.", 1)
        return True

    tmp_path = CORE_INFO + ".tmp"
    # TOML is always UTF-8; pin it so a C/POSIX-locale box doesn't write in
    # ASCII and choke on a non-ASCII help char (the read side is rb+tomllib,
    # i.e. already UTF-8, so an unpinned write would be asymmetric).
    with open(tmp_path, "w", encoding="utf-8") as out_file:
        out_file.write(text)
    os.replace(tmp_path, CORE_INFO)
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
        return 0
    try:
        with open(include_list, "rb") as list_file:
            paths = tomllib.load(list_file).get("paths", [])
    except tomllib.TOMLDecodeError as error:
        log(f"Could not parse {include_list}: {error!r}")
        log("Fix the include list, then re-run setup.")
        return EXIT_MERGE_SKIPPED
    if not isinstance(paths, list):
        # A bare string would otherwise iterate character-by-character below.
        log(f"`paths` in {include_list} must be an array of strings.")
        return EXIT_MERGE_SKIPPED

    toml_writer = load_toml_writer()
    any_skipped = False
    for raw_path in paths:
        # Isolate each entry: one malformed list element (non-string), a flaky
        # git repo, or a bad include _info.toml must not sink the others. Ruby
        # let one bad entry abort the loop; we soft-skip it and carry on. The
        # expand + isdir checks live inside the try too, since a non-string
        # entry raises in expand_include_path.
        try:
            path = expand_include_path(raw_path)
            if not os.path.isdir(path):
                continue
            log(raw_path)
            if os.path.isdir(os.path.join(path, ".git")):
                update_include_repo(path)
            link_docs(path)
            if link_scripts(path, toml_writer):
                any_skipped = True
        except Exception as error:
            log(f"Skipped {raw_path!r} — {error!r}", 1)
            log("Fix this include, then re-run setup.", 1)
            any_skipped = True

    return EXIT_MERGE_SKIPPED if any_skipped else 0


if __name__ == "__main__":
    sys.exit(process_includes())
