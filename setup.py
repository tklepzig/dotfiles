#!/usr/bin/env python3
# Bootstrap installer. Runs on a FRESH box's python via `python3 -c "$(curl …)"`,
# so it must stay STDLIB-ONLY and low-floor (3.8/3.9-safe) — no tomllib, no
# third-party imports. The modern-python-only bits (toolbox-include TOML merge)
# come later and run under a provisioned interpreter. Python port of setup.rb.

import importlib.util
import os
import pwd
import re
import shutil
import subprocess
import sys
from contextlib import contextmanager
from pathlib import Path
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
    # Ensure the target exists (create its parent dir + an empty file; never
    # truncate an existing file), add the base link, then add its whole-file
    # override if one exists.
    if not os.path.exists(file):
        os.makedirs(os.path.dirname(file), exist_ok=True)
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


def resolve_modern_python():
    """Return the path to a python >= 3.11 for the toolbox-include merge (it
    needs `tomllib` to read the include list + validate each include's
    `_info.toml`, unavailable on setup.py's low bootstrap floor).

    Fast path: the running interpreter already qualifies — true on every current
    Linux and modern macOS. Otherwise look for a modern python already on PATH.
    Returns None if none is found, so the caller can soft-skip with guidance.

    UNVERIFIED below the fast path: this box runs 3.11+, so the search/None
    branches are reasoned, not exercised. The whole include feature is off the
    fresh-install path (guarded by toolbox-include.toml), so a user reaching here
    is not on a bare box and most likely already has a modern python.
    """
    # `minimum` is a variable, not a literal, on purpose: pyright constant-folds
    # `sys.version_info >= (3, 11)` against the interpreter it runs under (modern),
    # then flags the search/None fallback as unreachable. The fallback is real on
    # an old bootstrap python — the indirection keeps it from being grayed out.
    minimum = (3, 11)
    if sys.version_info >= minimum:
        return sys.executable
    for candidate in ("python3.14", "python3.13", "python3.12", "python3.11"):
        found = shutil.which(candidate)
        if found:
            return found
    return None


def add_toolbox_includes():
    # Off the fresh-install path: only users with a toolbox-include.toml are
    # affected, so a bare box returns immediately and never needs modern python.
    include_list = f"{DF_LOCAL_PATH}/toolbox-include.toml"
    if not os.path.exists(include_list):
        return

    with Logger.log("Processing includes"):
        modern_python = resolve_modern_python()
        if modern_python is None:
            Logger.error(
                "Toolbox includes need python >= 3.11 (none found). Install one "
                "and re-run setup to finish linking includes."
            )
            return
        # The helper needs tomllib to read the include list + validate each
        # include's _info.toml, so it runs in a separate process under the modern
        # interpreter — setup.py's own imports stay stdlib-only/low-floor. Exit 2
        # = an include was soft-skipped (bad data).
        result = subprocess.run([modern_python, f"{DF_PATH}/toolbox/setup_includes.py"])
        if result.returncode != 0:
            Logger.error(
                "Some toolbox includes were skipped (see above). Re-run setup once "
                "resolved — it is idempotent and will finish them."
            )


def sync_vim_plugins(variant):
    # TODO (Ruby carryover): part of vim setup. Can't rely on zsh aliases — the
    # subprocess shell is sh and doesn't know them, so call the binary directly.
    # stdin=DEVNULL on every editor call (port-time hardening, like the git
    # calls): a headless editor must never block waiting on input. Ruby piped
    # `echo |` into the coc/plug calls for the same reason.
    vim_binary = "nvim" if variant == "neovim" else "vim"
    if variant == "neovim":
        Logger.log("Installing and syncing neovim plugins")
        subprocess.run(
            [vim_binary, "--headless", "+Lazy! sync", "+qa"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        Logger.log("Updating coc extensions")
        subprocess.run(
            [vim_binary, "+CocUpdateSync", "+qall"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    else:
        plug_file = f"{HOME}/.vim/autoload/plug.vim"
        if not os.path.exists(plug_file):
            Logger.log("Installing vim-plug")
            subprocess.run(
                ["curl", "-fLo", plug_file, "--create-dirs",
                 "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        Logger.log("Installing and updating vim plugins")
        subprocess.run(
            [vim_binary, "+PlugInstall", "+PlugUpdate", "+qall"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


def install_tmux_snapshot_scheduler():
    # Periodic tmux snapshots: a LaunchAgent on macOS, a systemd user timer on
    # Linux. The plist/units reference DF_PATH (= ~/.dotfiles), the installed
    # clone — never the dev checkout.
    os.makedirs(f"{DF_LOCAL_PATH}/tmux-snapshot", exist_ok=True)

    if is_mac():
        # UNVERIFIED on this Linux box — the launchd branch isn't exercised here.
        Logger.log("Installing tmux-snapshot LaunchAgent")
        launch_agents = f"{HOME}/Library/LaunchAgents"
        os.makedirs(launch_agents, exist_ok=True)
        plist_src = f"{DF_PATH}/tmux/scheduler/dev.dotfiles.tmux-snapshot.plist"
        plist_dst = f"{launch_agents}/dev.dotfiles.tmux-snapshot.plist"
        with open(plist_src, encoding="utf-8") as source:
            rendered = source.read().replace("__DF_PATH__", DF_PATH).replace("__HOME__", HOME)
        existing = None
        if os.path.exists(plist_dst):
            with open(plist_dst, encoding="utf-8") as current:
                existing = current.read()
        # Only reload when the rendered content actually changed.
        if rendered != existing:
            with open(plist_dst, "w", encoding="utf-8") as destination:
                destination.write(rendered)
            uid = os.getuid()
            # bootout is best-effort (fails if not loaded); ignore its result.
            subprocess.run(
                ["launchctl", "bootout", f"gui/{uid}/dev.dotfiles.tmux-snapshot"],
                stderr=subprocess.DEVNULL,
            )
            subprocess.run(["launchctl", "bootstrap", f"gui/{uid}", plist_dst])
    elif is_linux():
        Logger.log("Installing tmux-snapshot systemd user units")
        unit_dir = f"{HOME}/.config/systemd/user"
        os.makedirs(unit_dir, exist_ok=True)
        force_symlink(
            f"{DF_PATH}/tmux/scheduler/tmux-snapshot.service",
            f"{unit_dir}/tmux-snapshot.service",
        )
        force_symlink(
            f"{DF_PATH}/tmux/scheduler/tmux-snapshot.timer",
            f"{unit_dir}/tmux-snapshot.timer",
        )
        subprocess.run(["systemctl", "--user", "daemon-reload"])
        subprocess.run(["systemctl", "--user", "enable", "--now", "tmux-snapshot.timer"])


def configure_tmux():
    with Logger.log("Configuring tmux"):
        # TODO (Ruby carryover): move up into one linking block.
        if is_mac():
            Logger.log("Symlinking tmux variables for macOS")
            add_link_with_override(f"{DF_PATH}/tmux/vars.osx.conf", f"{HOME}/.tmux.conf")
        else:
            Logger.log("Symlinking tmux variables for Linux")
            add_link_with_override(f"{DF_PATH}/tmux/vars.linux.conf", f"{HOME}/.tmux.conf")
        Logger.log("Symlinking tmux main configuration")
        add_link_with_override(f"{DF_PATH}/tmux/tmux.conf", f"{HOME}/.tmux.conf")

        install_tmux_snapshot_scheduler()


def configure_kitty():
    if not program_installed("kitty"):
        return
    Logger.log("Configuring kitty")
    add_link_with_override(
        f"{DF_PATH}/kitty/kitty.conf", f"{HOME}/.config/kitty/kitty.conf", "include"
    )
    if is_mac():
        Logger.log("Symlinking kitty variables for macOS")
        add_link_with_override(
            f"{DF_PATH}/kitty/kitty.macos.conf", f"{HOME}/.config/kitty/kitty.conf", "include"
        )
    else:
        Logger.log("Symlinking kitty variables for Linux")
        add_link_with_override(
            f"{DF_PATH}/kitty/kitty.linux.conf", f"{HOME}/.config/kitty/kitty.conf", "include"
        )
    add_link_with_override(
        f"{DF_PATH}/kitty/kitty.theme.conf", f"{HOME}/.config/kitty/kitty.conf", "include"
    )


def configure_ranger():
    if not program_installed("ranger"):
        return
    Logger.log("Configuring ranger")
    os.makedirs(f"{HOME}/.config/ranger", exist_ok=True)
    force_symlink(f"{DF_PATH}/ranger/rc.conf", f"{HOME}/.config/ranger/rc.conf")


def configure_mpv():
    if not program_installed("mpv"):
        return
    Logger.log("Configuring mpv")
    os.makedirs(f"{HOME}/.config/mpv", exist_ok=True)
    force_symlink(f"{DF_PATH}/mpv/mpv.conf", f"{HOME}/.config/mpv/mpv.conf")
    force_symlink(f"{DF_PATH}/mpv/input.conf", f"{HOME}/.config/mpv/input.conf")


def configure_i3():
    if not program_installed("i3"):
        return
    with Logger.log("Configuring i3"):
        Logger.log("Symlinking i3 main configuration")
        add_link_with_override(f"{DF_PATH}/i3/config", f"{HOME}/.config/i3/config", "include")

        Logger.log("Symlinking i3blocks configuration")
        os.makedirs(f"{HOME}/.config/i3blocks", exist_ok=True)
        force_symlink(f"{DF_PATH}/i3/i3blocks.config", f"{HOME}/.config/i3blocks/config")

        Logger.log("Symlinking dunst configuration")
        os.makedirs(f"{HOME}/.config/dunst", exist_ok=True)
        force_symlink(f"{DF_PATH}/i3/dunst.config", f"{HOME}/.config/dunst/dunstrc")

        Logger.log("Symlinking picom configuration")
        os.makedirs(f"{HOME}/.config/picom", exist_ok=True)
        force_symlink(f"{DF_PATH}/i3/picom.config", f"{HOME}/.config/picom/picom.conf")


def configure_aerospace():
    if not is_mac():
        return
    # UNVERIFIED on this Linux box — macOS-only.
    Logger.log("Configuring aerospace for macOS")
    force_symlink(f"{DF_PATH}/aerospace/config.toml", f"{HOME}/.aerospace.toml")
    with Logger.log("Ensuring macOS dependencies"):
        ensure_brew_package("nowplaying-cli")


def install_fzf():
    if os.path.exists(f"{HOME}/.fzf"):
        return
    Logger.log("Installing fzf")
    subprocess.run(
        ["git", "clone", "--depth", "1", "https://github.com/junegunn/fzf.git", f"{HOME}/.fzf"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    # If the clone failed (network/rate-limit), the installer won't exist — skip
    # rather than crash the whole setup at its last step (Ruby swallowed both).
    if os.path.exists(f"{HOME}/.fzf/install"):
        subprocess.run(
            [f"{HOME}/.fzf/install", "--all"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


def install_docker_completion():
    if not program_installed("docker"):
        return
    Logger.log("Installing docker completion")
    completion_dir = f"{HOME}/.zsh/completion"
    os.makedirs(completion_dir, exist_ok=True)
    completions = {
        "_docker": "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker",
        "_docker-compose": "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose",
    }
    for name, url in completions.items():
        # `curl -L URL > file 2>/dev/null` → -o writes the file, stderr silenced.
        subprocess.run(["curl", "-L", "-o", f"{completion_dir}/{name}", url], stderr=subprocess.DEVNULL)


def set_default_shell_to_zsh():
    # Ruby read the login shell via `dscl`(mac) / `grep /etc/passwd`(linux); the
    # stdlib `pwd` module returns it portably in one call. chsh only if needed.
    zsh_path = shutil.which("zsh")
    if zsh_path is None:
        Logger.error("zsh not found on PATH — skipping default-shell change.")
        return
    try:
        current_shell = pwd.getpwuid(os.getuid()).pw_shell
    except KeyError:
        # Ephemeral/injected UID with no passwd entry (e.g. `docker run --user
        # 99999`): Ruby's grep degraded to "" and continued — mirror that.
        current_shell = None
    if current_shell != zsh_path:
        with Logger.log("Setting default shell to zsh"):
            subprocess.run(["chsh", "-s", zsh_path])
            Logger.log("Please notice: In order to use the new shell, you have to logout and back in.")


def run_post_install_script():
    script = f"{DF_LOCAL_PATH}/post-install"
    if not (os.path.isfile(script) and os.access(script, os.X_OK)):
        return
    with Logger.log("Running post install script"):
        # stdout=PIPE (not capture_output) so the script's stderr still reaches
        # the terminal, matching Ruby's backticks (which captured only stdout).
        result = subprocess.run([script], stdout=subprocess.PIPE, text=True)
        for line in result.stdout.splitlines():  # splitlines drops the trailing empty
            Logger.log(line)


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

    # Grouped with the other ~/.zshrc linking. Sits before setup_vim, which only
    # touches ~/.vimrc, so the .zshrc append order (colours.zsh -> zshrc ->
    # toolbox/init.zsh) is unchanged.
    add_link_with_override(f"{DF_PATH}/zsh/zshrc", f"{HOME}/.zshrc")

    setup_vim(variant)

    configure_bc()
    configure_ruby()

    with Logger.log("Initializing toolbox"):
        # TODO (Ruby carryover): only when in full mode?
        add_link_with_override(f"{DF_PATH}/toolbox/init.zsh", f"{HOME}/.zshrc")
        add_toolbox_includes()

    sync_vim_plugins(variant)
    configure_tmux()

    configure_kitty()
    configure_ranger()
    configure_mpv()
    configure_i3()
    configure_aerospace()

    install_fzf()

    Logger.log("Configuring Git")
    subprocess.run([f"{DF_PATH}/git/install"])

    install_docker_completion()
    set_default_shell_to_zsh()
    run_post_install_script()

    Logger.success("Setup done.")


def remove_links(pattern, file):
    # Drop every line matching `pattern` (a regex) from `file`. Ruby shelled out
    # to `sed "/pattern/d"`; we filter natively.
    # FAITHFUL QUIRK: Ruby's callers pass CWD-relative paths (".zshrc", not
    # f"{HOME}/.zshrc"), so this only touches the real dotfiles if uninstall runs
    # from $HOME. Likely a latent Ruby bug; replicated as-is, flagged for Step 10.
    if not os.path.exists(file):
        return
    Logger.log(f"Removing pattern '{pattern}' from {file}")
    matcher = re.compile(pattern)
    with open(file) as handle:
        kept = [line for line in handle if not matcher.search(line)]
    with open(file, "w") as handle:
        handle.write("".join(kept))


def uninstall():
    remove_links(r"\.dotfiles", ".zshrc")
    remove_links(r"\.fzf", ".zshrc")
    remove_links(r"\.dotfiles", ".vimrc")
    remove_links(r"\.dotfiles", ".tmux.conf")
    remove_links(r"\.dotfiles", ".config/kitty/kitty.conf")

    # Remove fzf wholesale so install re-adds its include AFTER the dotfiles zsh
    # includes next time.
    Logger.log("Removing fzf")
    shutil.rmtree(f"{HOME}/.fzf", ignore_errors=True)

    Logger.log("Removing vim-plug and vim plugins")
    Path(f"{HOME}/.vim/autoload/plug.vim").unlink(missing_ok=True)
    shutil.rmtree(f"{HOME}/.vim/vim-plug", ignore_errors=True)

    cleanup_vim()

    Logger.log("Removing bc configuration")
    Path(f"{HOME}/.bc").unlink(missing_ok=True)

    Logger.log("Removing default gems configuration")
    Path(f"{HOME}/.default-gems").unlink(missing_ok=True)

    Logger.log("Removing rubocop configuration")
    Path(f"{HOME}/.rubocop.yml").unlink(missing_ok=True)

    Logger.log("Removing git configuration")
    subprocess.run([f"{DF_PATH}/git/uninstall"])

    Logger.log("Removing dotfiles")
    shutil.rmtree(DF_PATH, ignore_errors=True)

    Logger.success("Successfully uninstalled dotfiles")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uninstall":
        uninstall()
    else:
        install("vim" if "--vim" in sys.argv else DF_VARIANT)
