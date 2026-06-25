#!/usr/bin/env python3
"""Tests for toolbox/setup_includes.py — the toolbox-include processor.

Nothing else exercises this path: it's behind the toolbox-include.toml guard, so
golden.py and the Docker harness both skip it. Run: python3 test/setup_includes_test.py

- The happy path runs the helper as a real subprocess (so the modern-python
  invocation is covered end-to-end), then merges info.d/ the way _run.py does to
  assert the runner will see the right metadata.
- Soft-skip paths assert the bad include drops out while the good one still lands
  and the committed core _info.toml is left untouched.
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


def read_time_merge(scripts_dir):
    """Reproduce _run.py's read-time merge: core, then info.d/*.toml sorted."""
    merged = tomllib.loads((scripts_dir / "_info.toml").read_text())
    info_d = scripts_dir / "info.d"
    if info_d.is_dir():
        for slot in sorted(info_d.glob("*.toml")):
            merged.update(tomllib.loads(slot.read_text()))
    return merged


class IntegrationTest(unittest.TestCase):
    def test_links_scripts_docs_and_registers_info(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            docs = home / ".dotfiles/toolbox/docs"
            scripts.mkdir(parents=True)
            docs.mkdir(parents=True)
            core_info = scripts / "_info.toml"
            original_core = '[core-script]\nhelp = "core"\n'
            core_info.write_text(original_core)

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

            # Scripts symlinked; the include's own _info.toml is NOT symlinked
            # into the scripts dir itself.
            self.assertTrue((scripts / "team-tool").is_symlink())
            self.assertFalse((scripts / "_info.toml").is_symlink())
            # Docs symlinked.
            self.assertTrue((docs / "team-tool.md").is_symlink())
            # The include's _info.toml is registered as an info.d slot pointing
            # back at the include, and the committed core file is left untouched.
            slot = scripts / "info.d" / "000-team-toolbox.toml"
            self.assertTrue(slot.is_symlink())
            self.assertEqual(os.path.realpath(slot), str(include / "scripts/_info.toml"))
            self.assertEqual(core_info.read_text(), original_core)
            # Read-time merge: both entries present, include wins the collision.
            merged = read_time_merge(scripts)
            self.assertEqual(set(merged), {"core-script", "team-tool"})
            self.assertEqual(merged["core-script"]["help"], "overridden")
            self.assertEqual(merged["team-tool"]["help"], "team")

    def test_later_include_wins_on_a_colliding_key(self):
        # Two includes define the same key; the one later in the list must win,
        # which the NN- slot prefix + sorted glob preserves.
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            (scripts / "_info.toml").write_text('[shared]\nhelp = "core"\n')

            first = home / "includes/aaa-first"
            (first / "scripts").mkdir(parents=True)
            (first / "scripts/_info.toml").write_text('[shared]\nhelp = "first"\n')
            second = home / "includes/zzz-second"
            (second / "scripts").mkdir(parents=True)
            (second / "scripts/_info.toml").write_text('[shared]\nhelp = "second"\n')

            local = home / ".dotfiles-local"
            local.mkdir()
            (local / "toolbox-include.toml").write_text(
                f'paths = ["{first}", "{second}"]\n'
            )

            result = subprocess.run(
                [sys.executable, str(HELPER)],
                env={**os.environ, "HOME": str(home)},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(read_time_merge(scripts)["shared"]["help"], "second")

    def test_one_broken_include_does_not_sink_the_next(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            original_core = '[core]\nhelp = "core"\n'
            (scripts / "_info.toml").write_text(original_core)

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
            # The broken one is never registered, so it can't poison _run.py.
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertTrue((scripts / "good-tool").is_symlink())
            self.assertFalse((scripts / "info.d" / "000-broken.toml").exists())
            self.assertTrue((scripts / "info.d" / "001-good.toml").is_symlink())
            self.assertEqual((scripts / "_info.toml").read_text(), original_core)
            self.assertIn("good-tool", read_time_merge(scripts))

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
            self.assertIn("good-tool", read_time_merge(scripts))

    def test_dropped_include_is_unregistered_on_rerun(self):
        # info.d is rebuilt each run, so removing an include from the list must
        # stop it being merged — the old in-place rewrite never un-merged.
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            (scripts / "_info.toml").write_text('[core]\nhelp = "core"\n')

            include = home / "includes/team-toolbox"
            (include / "scripts").mkdir(parents=True)
            (include / "scripts/_info.toml").write_text('[team-tool]\nhelp = "team"\n')

            local = home / ".dotfiles-local"
            local.mkdir()
            include_list = local / "toolbox-include.toml"

            env = {**os.environ, "HOME": str(home)}
            include_list.write_text(f'paths = ["{include}"]\n')
            subprocess.run([sys.executable, str(HELPER)], env=env, capture_output=True)
            self.assertIn("team-tool", read_time_merge(scripts))

            # Drop the include and re-run: its slot must be gone.
            include_list.write_text("paths = []\n")
            subprocess.run([sys.executable, str(HELPER)], env=env, capture_output=True)
            self.assertNotIn("team-tool", read_time_merge(scripts))

    def test_deleted_include_list_unregisters_stale_slots(self):
        # Deleting toolbox-include.toml entirely (not just emptying paths) is the
        # natural way to drop your last include — it must still wipe info.d, even
        # though process_includes early-returns on the absent file.
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            scripts = home / ".dotfiles/toolbox/scripts"
            scripts.mkdir(parents=True)
            (scripts / "_info.toml").write_text('[core]\nhelp = "core"\n')

            include = home / "includes/team-toolbox"
            (include / "scripts").mkdir(parents=True)
            (include / "scripts/_info.toml").write_text('[team-tool]\nhelp = "team"\n')

            local = home / ".dotfiles-local"
            local.mkdir()
            include_list = local / "toolbox-include.toml"

            env = {**os.environ, "HOME": str(home)}
            include_list.write_text(f'paths = ["{include}"]\n')
            subprocess.run([sys.executable, str(HELPER)], env=env, capture_output=True)
            self.assertIn("team-tool", read_time_merge(scripts))

            # Remove the list file entirely and re-run: the stale slot must go.
            include_list.unlink()
            subprocess.run([sys.executable, str(HELPER)], env=env, capture_output=True)
            self.assertFalse((scripts / "info.d").is_dir())
            self.assertNotIn("team-tool", read_time_merge(scripts))

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


if __name__ == "__main__":
    unittest.main()
