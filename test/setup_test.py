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

    def test_ensure_asdf_python_fast_path(self):
        # This interpreter is >= 3.11, so it must be returned as-is (no search).
        self.assertEqual(setup.ensure_asdf_python(), sys.executable)

    def test_add_toolbox_includes_is_noop_without_list(self):
        tmp = tempfile.mkdtemp()  # no toolbox-include.toml here
        saved_local, saved_ensure = setup.DF_LOCAL_PATH, setup.ensure_asdf_python

        def fail(*_args, **_kwargs):
            raise AssertionError("guard must return before resolving python")

        setup.DF_LOCAL_PATH = tmp
        setup.ensure_asdf_python = fail
        try:
            self.assertIsNone(setup.add_toolbox_includes())
        finally:
            setup.DF_LOCAL_PATH, setup.ensure_asdf_python = saved_local, saved_ensure


if __name__ == "__main__":
    unittest.main()
