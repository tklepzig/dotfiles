#!/usr/bin/env python3
"""Tests for toolbox/setup_includes.py — the toolbox-include processor.

Nothing else exercises this path: it's behind the toolbox-include.toml guard, so
golden.py and the Docker harness both skip it. Run: python3 test/setup_includes_test.py

- The happy path runs the helper as a real subprocess (so _vendor resolution and
  the modern-python invocation are covered end-to-end).
- Plan B is tested at function level by overriding the module's path globals.
"""
import os
import subprocess
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest import mock

REPO = Path(__file__).resolve().parent.parent
HELPER = REPO / "toolbox" / "setup_includes.py"

sys.path.insert(0, str(REPO / "toolbox"))
import setup_includes  # noqa: E402


class IntegrationTest(unittest.TestCase):
    def test_links_scripts_docs_and_merges_info(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            docs = home / ".dotfiles/toolbox/docs"
            scripts.mkdir(parents=True)
            docs.mkdir(parents=True)
            core_info = scripts / "_info.toml"
            core_info.write_text('[core-script]\nhelp = "core"\n')

            include = home / "includes/team-toolbox"
            (include / "scripts").mkdir(parents=True)
            (include / "docs").mkdir(parents=True)
            (include / "scripts/team-tool").write_text("#!/bin/sh\necho hi\n")
            (include / "scripts/_info.toml").write_text(
                '[team-tool]\nhelp = "team"\n\n[core-script]\nhelp = "overridden"\n'
            )
            (include / "docs/team-tool.md").write_text("# team tool\n")

            local = home / ".dotfiles-local"
            local.mkdir()
            (local / "toolbox-include.toml").write_text(f'paths = ["{include}"]\n')

            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": str(home)},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            # Scripts symlinked; the include's own _info.toml is NOT linked.
            self.assertTrue((scripts / "team-tool").is_symlink())
            self.assertFalse((scripts / "_info.toml").is_symlink())
            # Docs symlinked.
            self.assertTrue((docs / "team-tool.md").is_symlink())
            # Merge: both entries present, include wins on the colliding key.
            merged = tomllib.loads(core_info.read_text())
            self.assertEqual(set(merged), {"core-script", "team-tool"})
            self.assertEqual(merged["core-script"]["help"], "overridden")
            self.assertEqual(merged["team-tool"]["help"], "team")

    def test_one_broken_include_does_not_sink_the_next(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            (scripts / "_info.toml").write_text('[core]\nhelp = "core"\n')

            broken = home / "includes/broken"
            (broken / "scripts").mkdir(parents=True)
            (broken / "scripts/_info.toml").write_text("this = is not ] valid toml")
            good = home / "includes/good"
            (good / "scripts").mkdir(parents=True)
            (good / "scripts/good-tool").write_text("#!/bin/sh\n")
            (good / "scripts/_info.toml").write_text('[good-tool]\nhelp = "good"\n')

            local = home / ".dotfiles-local"
            local.mkdir()
            (local / "toolbox-include.toml").write_text(
                f'paths = ["{broken}", "{good}"]\n'
            )

            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": str(home)},
                capture_output=True, text=True,
            )
            # Broken include soft-skips (exit 2) but the good one still lands.
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertTrue((scripts / "good-tool").is_symlink())
            merged = tomllib.loads((scripts / "_info.toml").read_text())
            self.assertIn("good-tool", merged)

    def test_non_string_list_entry_does_not_sink_the_next(self):
        # A fat-fingered list element (here an int) must soft-skip, not abort
        # the whole loop before the good include is processed.
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            (scripts / "_info.toml").write_text('[core]\nhelp = "core"\n')

            good = home / "includes/good"
            (good / "scripts").mkdir(parents=True)
            (good / "scripts/good-tool").write_text("#!/bin/sh\n")
            (good / "scripts/_info.toml").write_text('[good-tool]\nhelp = "good"\n')

            local = home / ".dotfiles-local"
            local.mkdir()
            (local / "toolbox-include.toml").write_text(f'paths = [123, "{good}"]\n')

            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": str(home)},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertTrue((scripts / "good-tool").is_symlink())
            self.assertIn("good-tool", tomllib.loads((scripts / "_info.toml").read_text()))

    def test_corrupt_include_list_soft_skips(self):
        with tempfile.TemporaryDirectory() as tmp:
            local = Path(tmp) / ".dotfiles-local"
            local.mkdir()
            (local / "toolbox-include.toml").write_text("this is ] not toml")
            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": tmp},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_missing_include_list_is_a_noop(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": tmp},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


def patch_global(test_case, name, value):
    # Set a setup_includes module global for the duration of one test and
    # auto-restore it afterwards, so these in-process tests aren't order-coupled.
    patcher = mock.patch.object(setup_includes, name, value)
    patcher.start()
    test_case.addCleanup(patcher.stop)


class ExpandPathTest(unittest.TestCase):
    def test_expand_include_path(self):
        patch_global(self, "DF_LOCAL_PATH", "/base")
        self.assertEqual(setup_includes.expand_include_path("/abs/path"), "/abs/path")
        self.assertEqual(setup_includes.expand_include_path("rel/path"), "/base/rel/path")
        self.assertEqual(setup_includes.expand_include_path("~"), os.path.expanduser("~"))


class PlanBTest(unittest.TestCase):
    """A failed merge must soft-skip AND leave the real _info.toml untouched."""

    def _fixture(self, tmp):
        home = Path(tmp)
        df_scripts = home / ".dotfiles/toolbox/scripts"
        df_scripts.mkdir(parents=True)
        core = df_scripts / "_info.toml"
        original = '[core]\nhelp = "core"\n'
        core.write_text(original)
        include = home / "inc"
        (include / "scripts").mkdir(parents=True)
        (include / "scripts/_info.toml").write_text('[new]\nhelp = "new"\n')
        patch_global(self, "DF_PATH", str(home / ".dotfiles"))
        patch_global(self, "CORE_INFO", str(core))
        return include, core, original

    def test_no_writer_soft_skips_and_preserves_core(self):
        with tempfile.TemporaryDirectory() as tmp:
            include, core, original = self._fixture(tmp)
            skipped = setup_includes.link_scripts(str(include), toml_writer=None)
            self.assertTrue(skipped)
            self.assertEqual(core.read_text(), original)

    def test_dump_error_soft_skips_and_preserves_core(self):
        class FailingWriter:
            def dumps(self, _data):
                raise ValueError("no null type in TOML")

        with tempfile.TemporaryDirectory() as tmp:
            include, core, original = self._fixture(tmp)
            skipped = setup_includes.link_scripts(str(include), FailingWriter())
            self.assertTrue(skipped)
            self.assertEqual(core.read_text(), original)


if __name__ == "__main__":
    unittest.main()
