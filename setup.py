#!/usr/bin/env python3
# Bootstrap installer. Runs on a FRESH box's python via `python3 -c "$(curl …)"`,
# so it must stay STDLIB-ONLY and low-floor (3.8/3.9-safe) — no tomllib, no
# third-party imports. The modern-python-only bits (toolbox-include TOML merge)
# come later and run under a provisioned interpreter. Python port of setup.rb.

import os
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


def install(variant=DF_VARIANT):
    # Filled in incrementally: program checks (Step 3), link helpers (4), repo
    # clone/update (5), .zshrc variant edit (6), vim (7), configs + python
    # provisioning + toolbox-includes (8), tail + post-install (9).
    raise NotImplementedError("setup.py install is being ported incrementally")


def uninstall():
    # Step 9.
    raise NotImplementedError("setup.py uninstall is being ported incrementally")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uninstall":
        uninstall()
    else:
        install("vim" if "--vim" in sys.argv else DF_VARIANT)
