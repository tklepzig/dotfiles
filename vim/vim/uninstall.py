#!/usr/bin/env python3
"""Vim (base) uninstall routine — loaded by setup.py via load_vim_routine.

Entry point is `run(context)`; `context` provides `.home`, `.df_path`, and
`.check_optional_installation`.
"""
from pathlib import Path


def run(context):
    # `rm -f`: remove if present, no error if missing.
    Path(f"{context.home}/.config/nvim/init.vim").unlink(missing_ok=True)
