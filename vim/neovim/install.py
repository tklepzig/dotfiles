#!/usr/bin/env python3
import os


def run(context):
    home = context.home
    df_path = context.df_path
    link = context.force_symlink

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
