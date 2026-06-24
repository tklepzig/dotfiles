#!/usr/bin/env python3
# Bootstrap installer. Runs on a FRESH box's python via `python3 -c "$(curl …)"`,
# so it must stay STDLIB-ONLY and low-floor (3.8/3.9-safe) — no tomllib, no
# third-party imports. The modern-python-only bits (toolbox-include TOML merge)
# come later and run under a provisioned interpreter. Python port of setup.rb.

import importlib.util
import os
import re
import shutil
import subprocess
import sys
from contextlib import contextmanager
from types import SimpleNamespace

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


def force_symlink(source, target):
    # `ln -sf`: drop any existing target (file or symlink, incl. broken), then
    # create the symlink. Single source of truth for every ported `ln -sf`.
    if os.path.islink(target) or os.path.exists(target):
        os.remove(target)
    os.symlink(source, target)


def git_short_hash():
    # Current short commit hash of the dotfiles repo.
    return subprocess.run(
        ["git", "rev-parse", "--short", "HEAD"],
        cwd=DF_PATH, capture_output=True, text=True,
    ).stdout.strip()


def update_dotfiles_repo():
    # Fast-forward an existing checkout to the remote tip. git is an external
    # tool → subprocess; cwd=DF_PATH per call replaces Ruby's `Dir.chdir` block,
    # so the process's own working directory is never mutated.
    with Logger.log(f"Found existing dotfiles in {DF_PATH}, updating"):
        current_hash = git_short_hash()

        # Pin the remote to the requested branch, if one is set.
        if DF_BRANCH:
            subprocess.run(
                ["git", "remote", "set-branches", "origin", DF_BRANCH], cwd=DF_PATH
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
            subprocess.run(["git", "checkout", "--quiet", DF_BRANCH], cwd=DF_PATH)

        Logger.success(f"Updated dotfiles from {current_hash} to {git_short_hash()}.")


def clone_dotfiles_repo():
    # Fresh shallow clone. The optional branch flag is a conditional list
    # extension, not shell-string interpolation.
    Logger.log(f"Cloning repo from {DF_REPO} to {DF_PATH}")
    if DF_BRANCH:
        Logger.success(f"Switching to branch {DF_BRANCH}")

    clone_command = ["git", "clone", "--quiet", "--depth=1"]
    if DF_BRANCH:
        clone_command += ["-b", DF_BRANCH]
    clone_command += [f"https://github.com/{DF_REPO}.git", DF_PATH]
    subprocess.run(clone_command)

    Logger.success(f"Installed dotfiles at {git_short_hash()}.")


def sync_dotfiles_repo():
    # --local installs straight from the working tree — nothing to clone/update.
    if DF_LOCAL:
        return

    if not os.path.isdir(DF_PATH):
        clone_dotfiles_repo()
        return

    update_dotfiles_repo()


def update_zshrc_variant(variant):
    # Ensure $DOTFILES_VARIANT is exported in ~/.zshrc, ABOVE the dotfiles zsh
    # source line (aliases sourced there depend on the variant being set first).
    variant_export = f"export DOTFILES_VARIANT='{variant}'"
    zshrc_path = f"{HOME}/.zshrc"
    source_line = f"{DF_PATH}/zsh/zshrc"

    # Ruby's File.read raises if ~/.zshrc is absent; default to empty so a fresh
    # box appends cleanly and the write below creates the file.
    zshrc = ""
    if os.path.exists(zshrc_path):
        with open(zshrc_path) as handle:
            zshrc = handle.read()

    if "DOTFILES_VARIANT" in zshrc:
        # Already present: replace in place, preserving its position. `.` doesn't
        # cross newlines, so `.*` stays line-bounded (matching Ruby's gsub!).
        zshrc = re.sub(r"export DOTFILES_VARIANT=.*", variant_export, zshrc)
    elif source_line in zshrc:
        # Source line present: insert the export above it. re.MULTILINE makes ^
        # match at each line start — Ruby's ^ is per-line by default, Python's
        # is string-start-only without the flag.
        zshrc = re.sub(
            rf"^(.*{re.escape(source_line)}.*)",
            lambda match: f"{variant_export}\n{match.group(1)}",
            zshrc,
            flags=re.MULTILINE,
        )
    else:
        # First install, source line not added yet: append (it follows later).
        zshrc += f"{variant_export}\n"

    with open(zshrc_path, "w") as handle:
        handle.write(zshrc)


def link_vim_plugins():
    # Apply the optional base-vim plugins override, then ensure each
    # `"pluginfile` marker in vim/plugins.vim is preceded by a source line for
    # the base plugins file (the Ruby sed, done natively). $HOME stays literal —
    # vim expands it when it sources the file.
    override = f"{DF_PATH}/vim/vim/plugins.override.vim"
    if os.path.exists(override):
        merge(f"{DF_PATH}/vim/vim/plugins.vim", override)

    plugins_file = f"{DF_PATH}/vim/plugins.vim"
    with open(plugins_file) as handle:
        content = handle.read()
    content = content.replace(
        '"pluginfile',
        'source $HOME/.dotfiles/vim/vim/plugins.vim\n"pluginfile',
    )
    with open(plugins_file, "w") as handle:
        handle.write(content)


def vim_routine_context():
    # The handful of names the vim install/uninstall routine files are allowed
    # to depend on. Passed as the single `context` argument to their run().
    return SimpleNamespace(
        home=HOME,
        df_path=DF_PATH,
        check_optional_installation=check_optional_installation,
        force_symlink=force_symlink,
    )


def load_vim_routine(relative_path):
    # Load a standalone routine file from the deployed repo and call run(context).
    # Loaded by absolute path (not import) because setup.py is curl-piped and the
    # routines live in the cloned repo — the Python analog of Ruby's `require`.
    routine_path = f"{DF_PATH}/{relative_path}"
    spec = importlib.util.spec_from_file_location("dotfiles_vim_routine", routine_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load vim routine: {routine_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.run(vim_routine_context())


def setup_theme_and_colours():
    os.makedirs(DF_LOCAL_PATH, exist_ok=True)

    if DF_THEME:
        Logger.log(f"Using theme {DF_THEME}")
    # set-theme writes the active theme files; like Ruby's backticks we ignore
    # its exit status (best-effort, no raise).
    subprocess.run([f"{DF_PATH}/toolbox/scripts/set-theme"])

    add_link_with_override(f"{DF_PATH}/colours.vim", f"{HOME}/.vimrc")
    add_link_with_override(f"{DF_PATH}/colours.zsh", f"{HOME}/.zshrc")
    add_link_with_override(f"{DF_PATH}/colours.tmux.conf", f"{HOME}/.tmux.conf")

    local_plugins = f"{DF_LOCAL_PATH}/plugins.vim"
    if not os.path.exists(local_plugins):
        # Seed a placeholder so the user has a known spot for personal plugins.
        # Byte-identical to setup.rb: a commented example, no trailing newline.
        with open(local_plugins, "w") as plugins_file:
            plugins_file.write("\"Plug 'any/vim-plugin'")

    add_link_with_override(f"{DF_PATH}/vim/plugins.vim", f"{HOME}/.vimrc")


def setup_vim(variant):
    with Logger.log(f"Setup {variant}"):
        link_vim_plugins()
        add_link_with_override(f"{DF_PATH}/vim/vim/vimrc", f"{HOME}/.vimrc")
        load_vim_routine("vim/vim/install.py")

        if variant != "neovim":
            return

        add_link_with_override(f"{DF_PATH}/vim/neovim/vimrc", f"{HOME}/.vimrc")
        load_vim_routine("vim/neovim/install.py")


def cleanup_vim():
    with Logger.log("Cleanup vim"):
        load_vim_routine("vim/vim/uninstall.py")

        if DF_VARIANT != "neovim":
            return

        load_vim_routine("vim/neovim/uninstall.py")


def configure_bc():
    bc_config = f"{HOME}/.bc"
    if not os.path.exists(bc_config):
        Logger.log("Configuring bc")
        # Default bc to 2 decimal places of precision.
        with open(bc_config, "w") as bc_file:
            bc_file.write("scale=2\n")


def configure_ruby():
    with Logger.log("Configuring ruby"):
        Logger.log("Symlinking default gems configuration")
        force_symlink(f"{DF_PATH}/ruby/default-gems", f"{HOME}/.default-gems")
        Logger.log("Symlinking rubocop configuration")
        force_symlink(f"{DF_PATH}/ruby/rubocop.yml", f"{HOME}/.rubocop.yml")


def install(variant=DF_VARIANT):
    check_mandatory_installation("git")
    check_mandatory_installation("zsh")

    check_optional_installation("eza")
    check_optional_installation("tmux")
    check_optional_installation("lynx")

    sync_dotfiles_repo()

    # Set the chosen variant in ~/.zshrc before the dotfiles source line.
    update_zshrc_variant(variant)

    # Theme + colours + local plugins.vim must be linked before vim setup.
    setup_theme_and_colours()

    setup_vim(variant)

    # TODO: move before vim setup (setup.rb has this TODO too; kept here to
    # match Ruby's actual order — don't enact the move during the port).
    add_link_with_override(f"{DF_PATH}/zsh/zshrc", f"{HOME}/.zshrc")

    configure_bc()
    configure_ruby()

    # Steps 8c–9 still to come: toolbox + python provisioning, remaining config
    # blocks, tail + post-install.
    raise NotImplementedError("setup.py install is being ported incrementally")


def uninstall():
    # Step 9.
    raise NotImplementedError("setup.py uninstall is being ported incrementally")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uninstall":
        uninstall()
    else:
        install("vim" if "--vim" in sys.argv else DF_VARIANT)
