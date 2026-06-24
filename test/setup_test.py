#!/usr/bin/env python3
"""Unit tests for the pure-logic helpers in setup.py.

setup.py is stdlib-only and normally curl-piped, so we load it by path and
monkeypatch its module globals (HOME/DF_PATH) onto a scratch dir. These cover
the regex-heavy branches the Docker harness never exercises — it runs setup
once against a fresh ~/.zshrc, so only the append branch runs there.

Run: python3 test/setup_test.py
"""
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parent.parent
SETUP_PATH = REPO_ROOT / "setup.py"


def load_setup():
    # Load by path under a throwaway name so the `__main__` guard doesn't fire
    # (install() must not run on import).
    spec = importlib.util.spec_from_file_location("setup_under_test", SETUP_PATH)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load setup module: {SETUP_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


setup = load_setup()


class FindOverrideTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def _touch(self, name):
        path = os.path.join(self.tmp, name)
        Path(path).touch()
        return path

    def test_suffix_form(self):
        # foo.vim.override sitting next to foo.vim
        base = os.path.join(self.tmp, "foo.vim")
        override = self._touch("foo.vim.override")
        self.assertEqual(setup.find_override(base), override)

    def test_before_extension_form(self):
        # foo.override.vim — exercises the re.sub before-extension branch
        base = os.path.join(self.tmp, "foo.vim")
        override = self._touch("foo.override.vim")
        self.assertEqual(setup.find_override(base), override)

    def test_no_override_returns_none(self):
        base = os.path.join(self.tmp, "foo.vim")
        self.assertIsNone(setup.find_override(base))

    def test_no_extension_returns_none(self):
        # No dot to split on: the regex no-ops, and the guard must return None
        # rather than the file itself (the latent Ruby bug we avoid).
        base = os.path.join(self.tmp, "noext")
        self.assertIsNone(setup.find_override(base))


class UpdateZshrcVariantTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.zshrc = os.path.join(self.tmp, ".zshrc")
        self._saved = (setup.HOME, setup.DF_PATH)
        setup.HOME = self.tmp
        setup.DF_PATH = os.path.join(self.tmp, ".dotfiles")

    def tearDown(self):
        setup.HOME, setup.DF_PATH = self._saved

    def _read(self):
        with open(self.zshrc) as handle:
            return handle.read()

    def test_append_when_absent(self):
        Path(self.zshrc).write_text("alias a=b\n")
        setup.update_zshrc_variant("vim")
        self.assertEqual(self._read(), "alias a=b\nexport DOTFILES_VARIANT='vim'\n")

    def test_replace_in_place(self):
        Path(self.zshrc).write_text("export DOTFILES_VARIANT='neovim'\nalias x=y\n")
        setup.update_zshrc_variant("vim")
        self.assertEqual(self._read(), "export DOTFILES_VARIANT='vim'\nalias x=y\n")

    def test_insert_above_source_line(self):
        source_line = f"{setup.DF_PATH}/zsh/zshrc"
        Path(self.zshrc).write_text(f"# top\nsource {source_line}\n")
        setup.update_zshrc_variant("vim")
        self.assertEqual(
            self._read(),
            f"# top\nexport DOTFILES_VARIANT='vim'\nsource {source_line}\n",
        )

    def test_creates_file_when_missing(self):
        # No ~/.zshrc on a fresh box — Ruby's File.read would have raised.
        setup.update_zshrc_variant("vim")
        self.assertEqual(self._read(), "export DOTFILES_VARIANT='vim'\n")


class MergeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def test_remove_and_add(self):
        base = os.path.join(self.tmp, "base")
        override = os.path.join(self.tmp, "override")
        Path(base).write_text("alpha\nbeta\ngamma\n")
        Path(override).write_text("-beta\ndelta\n")
        setup.merge(base, override)
        self.assertEqual(Path(base).read_text(), "alpha\ngamma\ndelta\n")


class ToolboxIncludesGlueTest(unittest.TestCase):
    """The setup.py-side glue. The full install()->helper path needs a deployed
    ~/.dotfiles clone, so only the guard + fast path are unit-testable here."""

    def test_resolve_modern_python_fast_path(self):
        # This interpreter is >= 3.11, so it must be returned as-is (no search).
        self.assertEqual(setup.resolve_modern_python(), sys.executable)

    def test_add_toolbox_includes_is_noop_without_list(self):
        tmp = tempfile.mkdtemp()  # no toolbox-include.toml here
        saved_local, saved_resolve = setup.DF_LOCAL_PATH, setup.resolve_modern_python

        def fail(*_args, **_kwargs):
            raise AssertionError("guard must return before resolving python")

        setup.DF_LOCAL_PATH = tmp
        setup.resolve_modern_python = fail
        try:
            self.assertIsNone(setup.add_toolbox_includes())
        finally:
            setup.DF_LOCAL_PATH, setup.resolve_modern_python = saved_local, saved_resolve


class RemoveLinksTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def test_drops_only_matching_lines(self):
        target = os.path.join(self.tmp, "zshrc")
        Path(target).write_text(
            "source ~/.dotfiles/zsh/zshrc\n"
            "alias ll='ls -la'\n"
            "source ~/.fzf.zsh\n"
        )
        setup.remove_links(r"\.dotfiles", target)
        remaining = Path(target).read_text()
        self.assertNotIn(".dotfiles", remaining)
        self.assertIn("alias ll", remaining)        # untouched
        self.assertIn(".fzf.zsh", remaining)         # different pattern, kept

    def test_missing_file_is_a_noop(self):
        # No raise when the (CWD-relative, in Ruby) target doesn't exist.
        setup.remove_links(r"\.dotfiles", os.path.join(self.tmp, "absent"))


class ConfigBlocksTest(unittest.TestCase):
    """Step 8d config blocks. They're all gated (program_installed / mac-only)
    so the Linux Docker harness skips them — these are their only coverage. Run
    under a temp HOME/DF_PATH and a mocked subprocess so a real machine's
    ~/.config and systemctl are never touched (kitty/ranger/mpv/i3 are actually
    installed on the dev box)."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.home = os.path.join(self.tmp, "home")
        self.df_path = os.path.join(self.tmp, "dotfiles")
        os.makedirs(self.home)
        os.makedirs(self.df_path)
        self._patch("HOME", self.home)
        self._patch("DF_PATH", self.df_path)
        self._patch("DF_LOCAL_PATH", os.path.join(self.home, ".dotfiles-local"))

    def _patch(self, attr, value):
        patcher = mock.patch.object(setup, attr, value)
        patcher.start()
        self.addCleanup(patcher.stop)

    def _source(self, relative):
        # Create a stub source file under DF_PATH so symlinks have a target.
        path = os.path.join(self.df_path, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        Path(path).write_text("stub\n")
        return path

    def test_configure_ranger_is_noop_when_absent(self):
        self._patch("program_installed", lambda _name: False)
        setup.configure_ranger()
        self.assertFalse(os.path.exists(os.path.join(self.home, ".config/ranger")))

    def test_configure_ranger_links_when_present(self):
        self._patch("program_installed", lambda _name: True)
        source = self._source("ranger/rc.conf")
        setup.configure_ranger()
        link = os.path.join(self.home, ".config/ranger/rc.conf")
        self.assertTrue(os.path.islink(link))
        self.assertEqual(os.readlink(link), source)

    def test_configure_i3_links_all_components(self):
        self._patch("program_installed", lambda _name: True)
        for name in ("i3/config", "i3/i3blocks.config", "i3/dunst.config", "i3/picom.config"):
            self._source(name)
        os.makedirs(os.path.join(self.home, ".config/i3"))  # Ruby assumes it exists
        setup.configure_i3()
        self.assertTrue(os.path.islink(os.path.join(self.home, ".config/i3blocks/config")))
        self.assertTrue(os.path.islink(os.path.join(self.home, ".config/dunst/dunstrc")))
        self.assertTrue(os.path.islink(os.path.join(self.home, ".config/picom/picom.conf")))
        # i3 main config is an `include` directive appended, not a symlink.
        with open(os.path.join(self.home, ".config/i3/config")) as handle:
            self.assertIn("include", handle.read())

    def test_sync_vim_plugins_neovim_invokes_lazy_and_coc(self):
        with mock.patch.object(setup.subprocess, "run") as run:
            setup.sync_vim_plugins("neovim")
        commands = [call.args[0] for call in run.call_args_list]
        self.assertIn(["nvim", "--headless", "+Lazy! sync", "+qa"], commands)
        self.assertIn(["nvim", "+CocUpdateSync", "+qall"], commands)

    def test_sync_vim_plugins_vim_installs_plug_then_updates(self):
        with mock.patch.object(setup.subprocess, "run") as run:
            setup.sync_vim_plugins("vim")  # plug.vim absent under temp HOME -> installs
        commands = [call.args[0] for call in run.call_args_list]
        self.assertTrue(any(cmd[0] == "curl" for cmd in commands))
        self.assertIn(["vim", "+PlugInstall", "+PlugUpdate", "+qall"], commands)

    def test_scheduler_linux_links_units_and_reloads(self):
        self._patch("is_mac", lambda: False)
        self._patch("is_linux", lambda: True)
        with mock.patch.object(setup.subprocess, "run") as run:
            setup.install_tmux_snapshot_scheduler()
        unit_dir = os.path.join(self.home, ".config/systemd/user")
        self.assertTrue(os.path.islink(os.path.join(unit_dir, "tmux-snapshot.service")))
        self.assertTrue(os.path.islink(os.path.join(unit_dir, "tmux-snapshot.timer")))
        commands = [call.args[0] for call in run.call_args_list]
        self.assertIn(["systemctl", "--user", "daemon-reload"], commands)
        self.assertIn(["systemctl", "--user", "enable", "--now", "tmux-snapshot.timer"], commands)


if __name__ == "__main__":
    unittest.main()
