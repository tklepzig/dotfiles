#!/usr/bin/env python3
"""Golden-output harness for the _run.rb -> _run.py port.

The toolbox runner's stdout is a parsed contract (consumed by init.zsh and the
_ws / _k completions), so the Python port must be byte-identical to the Ruby
original. This harness snapshots _run.rb's stdout + exit code for every mode in
the verification matrix, then lets us diff a candidate runner against it.

Run from anywhere:
    toolbox/test/golden.py capture          # run _run.rb, (re)write golden/
    toolbox/test/golden.py verify           # run _run.py, diff vs golden/
    toolbox/test/golden.py verify <runner>  # diff an explicit runner path

The runner is invoked under a throwaway $HOME whose .dotfiles symlinks back to
this dev clone, because _run.* derives its scripts path from
"$HOME/.dotfiles/toolbox/scripts". That isolates us from whatever the deployed
~/.dotfiles clone happens to be checked out at, and keeps the invocation
interpreter-agnostic so the same CASES drive _run.py later with zero edits.

NOT covered by the harness: the info.additional.yaml merge path (_run.rb:11-14)
has no fixture, since the dev clone ships no such file. It is behind a guard
absent on fresh boxes; revisit with a fixture only if that path changes.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = REPO_ROOT / "toolbox" / "scripts"
GOLDEN_DIR = Path(__file__).resolve().parent / "golden"

# Captured before we hand a throwaway HOME to the runner: the `ruby`/`python3`
# asdf shims resolve their interpreter install under $HOME/.asdf by default, so
# we must pin asdf at the real home or the shim exits 126 under our fake HOME.
REAL_HOME = os.environ["HOME"]
ASDF_DATA_DIR = os.environ.get("ASDF_DATA_DIR") or f"{REAL_HOME}/.asdf"

# Each case is (name, [argv...]). The name is the golden filename stem.
#
# These lock the "happy path" surface from the verification matrix. The subtle
# divergence cases (Ruby #{nil} -> "" vs Python "None"; puts trailing spaces)
# live in EDGE_CASES below.
CASES = [
    # --- introspection modes (stdout consumed verbatim by init.zsh) ---
    ("list", ["--list"]),
    ("details", ["--details"]),
    ("completion-help", ["--completion", "help"]),
    ("completion-set-theme", ["--completion", "set-theme"]),   # has a completion array
    ("completion-colours", ["--completion", "colours"]),       # in info, no completion key
    ("completion-unknown", ["--completion", "nonexistent"]),   # not in info at all
    # --- `help <script>` usage strings (arg formatting) ---
    ("help-set-theme", ["help", "set-theme"]),                 # <mandatory> + multiline help
    ("help-git-search", ["help", "git-search"]),               # single <mandatory>
    ("help-colours", ["help", "colours"]),                     # [optional = default]
    ("help-git-fetch-merge", ["help", "git-fetch-merge"]),     # [optional] no default
    ("help-unknown", ["help", "nonexistent"]),                 # Unknown script, exit 1
    # --- dispatch (just echoes the resolved script name on success) ---
    ("dispatch-list-ports", ["list-ports"]),                   # no args declared
    ("dispatch-colours-ok", ["colours", "4"]),                 # optional arg supplied
    ("dispatch-git-search-ok", ["git-search", "foo"]),         # mandatory arg supplied
    ("missing-arg", ["git-search"]),                           # all mandatory missing, exit 1
    ("missing-some", ["encrypt-clone", "foo"]),                # 1 of 2 mandatory given -> slice drops supplied prefix
    ("too-many-args", ["colours", "a", "b"]),                  # 2 given, 1 declared, exit 1
    ("unknown-script", ["nonexistent"]),                       # Unknown script, exit 1
]

# TODO(human): add the divergence-forcing edge cases here.
EDGE_CASES = [
    ("help-empty", ["help", ""]),
    ("help-nil", ["help"]),
    ("empty", []),
]

ALL_CASES = CASES + EDGE_CASES


def run_case(runner: Path, argv: list[str], home: Path) -> tuple[bytes, bytes, int]:
    """Invoke `runner` with argv under a throwaway HOME; return (stdout, stderr, exit)."""
    interpreter = {".rb": "ruby", ".py": "python3"}.get(runner.suffix)
    if interpreter is None:
        raise SystemExit(f"Don't know how to run {runner.name} (expected .rb or .py)")

    env = {
        **os.environ,
        "HOME": str(home),
        "ASDF_DATA_DIR": ASDF_DATA_DIR,
        "ASDF_DIR": ASDF_DATA_DIR,
    }
    result = subprocess.run(
        [interpreter, str(runner), *argv],
        capture_output=True,
        env=env,
    )
    return result.stdout, result.stderr, result.returncode


def make_home(tmp: Path) -> Path:
    """A fake $HOME whose .dotfiles points at this dev clone."""
    home = tmp / "home"
    home.mkdir()
    (home / ".dotfiles").symlink_to(REPO_ROOT)
    return home


def capture(runner: Path) -> int:
    GOLDEN_DIR.mkdir(exist_ok=True)
    manifest = {}
    with tempfile.TemporaryDirectory() as tmpdir:
        home = make_home(Path(tmpdir))
        for name, argv in ALL_CASES:
            stdout, stderr, code = run_case(runner, argv, home)
            if stderr:
                print(f"  ! {name}: unexpected stderr: {stderr!r}", file=sys.stderr)
            (GOLDEN_DIR / f"{name}.stdout").write_bytes(stdout)
            manifest[name] = {"argv": argv, "exit": code}
            print(f"  captured {name} (exit {code}, {len(stdout)} bytes)")
    (GOLDEN_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"\nWrote {len(manifest)} golden snapshots to {GOLDEN_DIR}")
    return 0


def verify(runner: Path) -> int:
    manifest = json.loads((GOLDEN_DIR / "manifest.json").read_text())
    failures = []
    with tempfile.TemporaryDirectory() as tmpdir:
        home = make_home(Path(tmpdir))
        for name, expected in manifest.items():
            stdout, stderr, code = run_case(runner, expected["argv"], home)
            golden_stdout = (GOLDEN_DIR / f"{name}.stdout").read_bytes()
            problems = []
            if stdout != golden_stdout:
                problems.append(f"stdout differs ({len(golden_stdout)} -> {len(stdout)} bytes)")
            if code != expected["exit"]:
                problems.append(f"exit {expected['exit']} -> {code}")
            if stderr:
                problems.append(f"stderr: {stderr!r}")
            if problems:
                failures.append((name, problems))
                print(f"  FAIL {name}: {'; '.join(problems)}")
            else:
                print(f"  ok   {name}")
    if failures:
        print(f"\n{len(failures)} of {len(manifest)} cases differ from golden")
        return 1
    print(f"\nAll {len(manifest)} cases match golden")
    return 0


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("capture", "verify"):
        print(__doc__)
        return 2
    mode = sys.argv[1]
    default_runner = "_run.rb" if mode == "capture" else "_run.py"
    runner = SCRIPTS_DIR / (sys.argv[2] if len(sys.argv) > 2 else default_runner)
    if not runner.exists():
        raise SystemExit(f"Runner not found: {runner}")
    return capture(runner) if mode == "capture" else verify(runner)


if __name__ == "__main__":
    raise SystemExit(main())
