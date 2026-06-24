#!/usr/bin/env python3
"""Vim (base) install routine — loaded by setup.py via load_vim_routine.

Edit freely to change what the base-vim install does. Entry point is
`run(context)`; `context` provides `.home`, `.df_path`, and
`.check_optional_installation`.
"""
import os


def run(context):
    for subdir in ("backup", ".swp", ".undo"):
        os.makedirs(f"{context.home}/.vim/{subdir}", exist_ok=True)
