#!/usr/bin/env python3
import shutil
from pathlib import Path


def run(context):
    home = context.home
    Path(f"{home}/.vim/coc-settings.json").unlink(missing_ok=True)
    Path(f"{home}/.config/nvim/coc-settings.json").unlink(missing_ok=True)
    shutil.rmtree(f"{home}/.config/solargraph", ignore_errors=True)
