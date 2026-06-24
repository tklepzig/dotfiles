#!/usr/bin/env python3
"""Neovim uninstall routine — loaded by setup.py via load_vim_routine.

Entry point is `run(context)`; `context` provides `.home`, `.df_path`, and
`.check_optional_installation`.
"""
import shutil
from pathlib import Path


def run(context):
    home = context.home
    # `rm -f` files, `rm -rf` the solargraph dir — no error if absent.
    Path(f"{home}/.vim/coc-settings.json").unlink(missing_ok=True)
    Path(f"{home}/.config/nvim/coc-settings.json").unlink(missing_ok=True)
    shutil.rmtree(f"{home}/.config/solargraph", ignore_errors=True)
