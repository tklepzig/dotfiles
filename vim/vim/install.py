#!/usr/bin/env python3
import os


def run(context):
    for subdir in ("backup", ".swp", ".undo"):
        os.makedirs(f"{context.home}/.vim/{subdir}", exist_ok=True)
