#!/usr/bin/env python3
"""Neovim install routine — loaded by setup.py via load_vim_routine.

Edit freely to change what the neovim install does. Entry point is
`run(context)`; `context` provides `.home`, `.df_path`, and
`.check_optional_installation`.
"""
import os


def link(source, target):
    # `ln -sf`: drop any existing target (file or symlink, incl. broken), then
    # create the symlink.
    if os.path.islink(target) or os.path.exists(target):
        os.remove(target)
    os.symlink(source, target)


def run(context):
    home = context.home
    df_path = context.df_path

    context.check_optional_installation("rg", "ripgrep")
    context.check_optional_installation("ranger")
    context.check_optional_installation("bat")

    os.makedirs(f"{home}/.vim", exist_ok=True)
    link(f"{df_path}/vim/neovim/coc-settings.json", f"{home}/.vim/coc-settings.json")

    os.makedirs(f"{home}/.config/solargraph", exist_ok=True)
    link(
        f"{df_path}/vim/neovim/solargraph.yaml",
        f"{home}/.config/solargraph/config.yml",
    )

    os.makedirs(f"{home}/.config/nvim/.undo", exist_ok=True)
    link(
        f"{df_path}/vim/neovim/coc-settings.json",
        f"{home}/.config/nvim/coc-settings.json",
    )

    os.makedirs(f"{home}/.config/nvim/lua/tkdf", exist_ok=True)
    link(f"{df_path}/vim/nvim-init.vim", f"{home}/.config/nvim/init.vim")
    link(
        f"{df_path}/vim/nvim-lazy-init.lua",
        f"{home}/.config/nvim/lua/tkdf/lazy-init.lua",
    )
    link(
        f"{df_path}/vim/nvim-lazy-plugins.lua",
        f"{home}/.config/nvim/lua/tkdf/lazy-plugins.lua",
    )
