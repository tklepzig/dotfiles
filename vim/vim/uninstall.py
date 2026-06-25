#!/usr/bin/env python3
from pathlib import Path


def run(context):
    Path(f"{context.home}/.config/nvim/init.vim").unlink(missing_ok=True)
