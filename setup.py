#!/usr/bin/env python3
# Bootstrap installer. Runs on a FRESH box's python via `python3 -c "$(curl …)"`,
# so it must stay STDLIB-ONLY and low-floor (3.8/3.9-safe) — no tomllib, no
# third-party imports. The modern-python-only bits (toolbox-include TOML merge)
# come later and run under a provisioned interpreter. Python port of setup.rb.

import os
import re
import shutil
import subprocess
import sys
from contextlib import contextmanager

DF_REPO = os.environ.get("DOTFILES_REPO", "tklepzig/dotfiles")
DF_BRANCH = os.environ.get("DOTFILES_BRANCH")  # None if unset
HOME = os.environ["HOME"]
DF_VARIANT = os.environ.get("DOTFILES_VARIANT", "neovim")
DF_THEME = os.environ.get("DOTFILES_THEME")  # None if unset
DF_PATH = f"{HOME}/.dotfiles"
DF_LOCAL_PATH = f"{HOME}/.dotfiles-local"
DF_LOCAL = "--local" in sys.argv

ARROW = "❯"


class Logger:
    """Indented ANSI logging. `Logger.log(msg)` prints a line; used as a
    `with` block it also indents everything logged inside it by two spaces:

        with Logger.log("Setting up vim"):
            Logger.log("Linking plugins")   # indented one level
        Logger.log("done")                  # back at top level

    A bare `Logger.log(msg)` (no `with`) just prints — the returned context
    manager is harmlessly discarded, so the indent only moves when entered.
    """

    _level = 0

    @classmethod
    def _format_line(cls, message, color):
        # Only the top level gets the bold arrow prefix; deeper levels are
        # indented two spaces per level instead.
        prefix = f"\x1b[1;38;5;{color}m{ARROW} " if cls._level == 0 else ""
        indent = " " * (2 * cls._level)
        return f"{prefix}\x1b[0;38;5;{color}m{indent}{message}\x1b[0m"

    @classmethod
    def log(cls, message):
        color = os.environ.get("primaryText", "4").replace("colour", "")
        print(cls._format_line(message, color))
        return cls._nested()

    @classmethod
    def success(cls, message):
        color = os.environ.get("accentText", "6").replace("colour", "")
        print(cls._format_line(message, color))

    @classmethod
    def error(cls, message):
        prefix = f"\x1b[1;31m{ARROW} " if cls._level == 0 else ""
        indent = " " * (2 * cls._level)
        print(f"{prefix}\x1b[0;31m{indent}{message}\x1b[0m")

    @classmethod
    @contextmanager
    def _nested(cls):
        cls._level += 1
        try:
            yield
        finally:
            cls._level = max(0, cls._level - 1)


def is_mac():
    return sys.platform == "darwin"


def is_linux():
    return sys.platform.startswith("linux")


def program_installed(program):
    return shutil.which(program) is not None


def ensure_brew_package(package, binary=None):
    binary = binary or package
    with Logger.log(f"Checking for {package}"):
        if program_installed(binary):
            Logger.success(f"Found: {shutil.which(binary)}.")
        else:
            Logger.log("Not found, installing via brew")
            # Matches Ruby's `system(...)`: fire-and-forget, exit code ignored.
            subprocess.run(["brew", "install", package])


def check_mandatory_installation(program):
    with Logger.log(f"Searching for {program}"):
        if not program_installed(program):
            Logger.error("Not found, aborting")
            sys.exit(1)
        Logger.success(f"Found: {shutil.which(program)}.")


def check_optional_installation(program, install_name=None):
    install_name = install_name or program
    with Logger.log(f"Searching for {program}"):
        if program_installed(program):
            Logger.success(f"Found: {shutil.which(program)}.")
        else:
            Logger.error(f'Not Found. (Try "sudo pacman -S {install_name}")')


def find_override(file_path):
    # Whole-file override lookup. Prefer `<path>.override`; else insert
    # `.override` before the final extension (foo.vim -> foo.override.vim).
    # Returns the override path if it exists on disk, else None.
    suffixed = f"{file_path}.override"
    if os.path.exists(suffixed):
        return suffixed

    # re.sub leaves the string unchanged when the pattern doesn't match; the
    # `!= file_path` guard stops us from returning the original file as its own
    # "override" in that no-extension case (a latent bug in the Ruby original).
    before_extension = re.sub(r"(.*)(\..+)$", r"\1.override\2", file_path)
    if before_extension != file_path and os.path.exists(before_extension):
        return before_extension

    return None


def merge(base_path, override_path):
    """Apply a line-level override file onto a base file, in place.

    The override is a small patch: a line `-<exact base line>` deletes that line
    from the base; every other override line is appended.
    """
    with open(base_path) as base_file:
        base_lines = base_file.readlines()
    with open(override_path) as override_file:
        override_lines = override_file.readlines()

    # Your removal filter (kept as-is): drop base lines the override marks for
    # deletion with a leading "-". Then append the override's own additions —
    # every override line that ISN'T a "-" removal marker.
    kept = [line for line in base_lines if f"-{line}" not in override_lines]
    additions = [line for line in override_lines if not line.startswith("-")]

    with open(base_path, "w") as base_file:
        base_file.write("".join(kept + additions))


def write_link(link, file, command="source"):
    # Idempotent append: skip if `link` is already referenced anywhere in the
    # file (Ruby used `grep -q`; substring presence is the same intent).
    if os.path.exists(file):
        with open(file) as handle:
            if link in handle.read():
                return

    with open(file, "a") as handle:
        handle.write(f"{command} {link}\n")


def add_link_with_override(link, file, command="source"):
    # Ensure the target exists (create empty; never truncate an existing file),
    # add the base link, then add its whole-file override if one exists.
    if not os.path.exists(file):
        open(file, "w").close()

    write_link(link, file, command)

    override = find_override(link)
    if override:
        write_link(override, file, command)


def install(variant=DF_VARIANT):
    check_mandatory_installation("git")
    check_mandatory_installation("zsh")

    check_optional_installation("eza")
    check_optional_installation("tmux")
    check_optional_installation("lynx")

    # Clone or update the dotfiles repo (skipped with --local, which installs
    # straight from the working tree). git is an external tool → subprocess.
    # Ruby scoped the cwd change with `Dir.chdir(DF_PATH) do … end`; we pass
    # cwd=DF_PATH per command instead, so the process's own working directory
    # is never mutated.
    if not DF_LOCAL:
        if os.path.isdir(DF_PATH):
            with Logger.log(f"Found existing dotfiles in {DF_PATH}, updating"):
                current_hash = subprocess.run(
                    ["git", "rev-parse", "--short", "HEAD"],
                    cwd=DF_PATH, capture_output=True, text=True
                ).stdout.strip()

                # Pin the remote to the requested branch, if one is set.
                if DF_BRANCH:
                    subprocess.run(
                        ["git", "remote", "set-branches", "origin", DF_BRANCH],
                        cwd=DF_PATH,
                    )

                # Fetch + hard-reset to the remote tip (output silenced, as in Ruby).
                subprocess.run(
                    ["git", "fetch", "--depth=1"],
                    cwd=DF_PATH, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )
                subprocess.run(
                    ["git", "reset", "--hard", f"origin/{DF_BRANCH or 'master'}"],
                    cwd=DF_PATH, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )

                if DF_BRANCH:
                    Logger.success(f"Switching to branch {DF_BRANCH}")
                    subprocess.run(
                        ["git", "checkout", "--quiet", DF_BRANCH], cwd=DF_PATH
                    )

                new_hash = subprocess.run(
                    ["git", "rev-parse", "--short", "HEAD"],
                    cwd=DF_PATH, capture_output=True, text=True
                ).stdout.strip()
                Logger.success(
                    f"Updated dotfiles from {current_hash} to {new_hash}."
                )
        else:
            Logger.log(f"Cloning repo from {DF_REPO} to {DF_PATH}")
            if DF_BRANCH:
                Logger.success(f"Switching to branch {DF_BRANCH}")

            # Build the clone command as an argv list; the optional branch flag
            # is just a conditional list extension (no shell-string quoting).
            clone_command = ["git", "clone", "--quiet", "--depth=1"]
            if DF_BRANCH:
                clone_command += ["-b", DF_BRANCH]
            clone_command += [f"https://github.com/{DF_REPO}.git", DF_PATH]
            subprocess.run(clone_command)

            installed_hash = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                cwd=DF_PATH, capture_output=True, text=True
            ).stdout.strip()
            Logger.success(f"Installed dotfiles at {installed_hash}.")

    # Steps 6–9 still to come: .zshrc variant edit, vim setup, configs + python
    # provisioning + toolbox-includes, tail + post-install.
    raise NotImplementedError("setup.py install is being ported incrementally")


def uninstall():
    # Step 9.
    raise NotImplementedError("setup.py uninstall is being ported incrementally")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uninstall":
        uninstall()
    else:
        install("vim" if "--vim" in sys.argv else DF_VARIANT)
