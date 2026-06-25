#!/usr/bin/env python3
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
    slot = os.path.join(INFO_D, f"{slot_index:03d}-{os.path.basename(path)}.toml")
    symlink_force(include_info, slot)
    return False


def expand_include_path(raw_path):
    expanded = os.path.expanduser(raw_path)
    if not os.path.isabs(expanded):
        expanded = os.path.join(DF_LOCAL_PATH, expanded)
    return os.path.abspath(expanded)


def update_include_repo(path):
    log("Found git repo, updating", 1)
    git_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    fetched = subprocess.run(
        ["git", "fetch"],
        cwd=path,
        env=git_env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if fetched.returncode == 0:
        subprocess.run(
            ["git", "merge", "--no-edit"],
            cwd=path,
            env=git_env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def process_includes():
    include_list = os.path.join(DF_LOCAL_PATH, "toolbox-include.toml")
    if not os.path.isfile(include_list):
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
        log(f"`paths` in {include_list} must be an array of strings.")
        return EXIT_INCLUDE_SKIPPED

    shutil.rmtree(INFO_D, ignore_errors=True)

    any_skipped = False
    for slot_index, raw_path in enumerate(paths):
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
