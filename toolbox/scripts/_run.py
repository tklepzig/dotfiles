#!/usr/bin/env python3
import os
import sys
import tomllib
from pathlib import Path

HOME = os.environ["HOME"]
SCRIPTS_PATH = Path(HOME) / ".dotfiles" / "toolbox" / "scripts"

# Infra files that are not toolbox scripts. Covers both config formats and both
# runners so the listing stays identical while .rb/.yaml and .py/.toml coexist
# during the port (deleted once the Ruby files go).
NON_SCRIPTS = {
    "_info.yaml",
    "_info.toml",
    "info.additional.yaml",
    "info.additional.toml",
    "_run.rb",
    "_run.py",
}

ESC = "\x1b"

with open(SCRIPTS_PATH / "_info.toml", "rb") as info_file:
    infos = tomllib.load(info_file)

additional_path = SCRIPTS_PATH / "info.additional.toml"
if additional_path.exists():
    with open(additional_path, "rb") as additional_file:
        additional = tomllib.load(additional_file)
    if additional:
        infos.update(additional)

# Ruby's Dir.glob is sorted since 3.0; pathlib's glob is not, so sort explicitly.
# Both skip dotfiles for a bare "*" pattern, matching Ruby.
scripts = sorted(
    entry.name for entry in SCRIPTS_PATH.glob("*") if entry.name not in NON_SCRIPTS
)

argv = sys.argv[1:]


def script_info(name):
    """The metadata dict for a script name, or None if absent/not a table."""
    info = infos.get(name)
    return info if isinstance(info, dict) else None


if argv and argv[0] == "--details":
    print(f"help:{ESC}[0;32;2mShow help for given command{ESC}[0m")
    for script in scripts:
        info = script_info(script)
        if info is not None and "help" in info:
            description = f":{ESC}[0;32;2m{info['help'].split(chr(10))[0]}{ESC}[0m"
        else:
            description = f":{ESC}[0;15;2mNo help for {script}{ESC}[0m"
        print(f"{script}{description}")
    sys.exit(0)

if argv and argv[0] == "--list":
    print("help")
    for script in scripts:
        print(script)
    sys.exit(0)

if argv and argv[0] == "--completion":
    if len(argv) > 1 and argv[1] == "help":
        for script in scripts:
            print(script)
    script = argv[1] if len(argv) > 1 else None
    info = script_info(script) if script is not None else None
    if info is not None and "completion" in info:
        print("\n".join(info["completion"]))
    sys.exit(0)

if argv and argv[0] == "help":
    script_name = argv[1] if len(argv) > 1 else None

    if script_name not in scripts:
        print(f"Unknown script {script_name or ''}")
        sys.exit(1)

    info = script_info(script_name)
    args_help = ""
    if info is not None and "args" in info:
        parts = []
        for arg in info["args"]:
            default_value = arg.get("default")
            # Ruby treats only nil/false as falsy, so a default of 0 would still
            # render. Gate on identity, not bare truthiness, to stay faithful.
            default = (
                f" = {default_value}"
                if default_value is not None and default_value is not False
                else ""
            )
            parts.append(
                f"[{arg['name']}{default}]" if arg.get("optional") else f"<{arg['name']}>"
            )
        args_help = " ".join(parts)
    print(f"Usage: {script_name} {args_help}")

    if info is not None and "help" in info:
        print("")
        print(info["help"])

    sys.exit(1)

script_name = argv[0] if argv else None

if script_name not in scripts:
    print(f"Unknown script {script_name or ''}")
    sys.exit(1)

info = script_info(script_name)
if info is not None and "args" in info:
    args = info["args"]
    cmd_args = argv[1:]

    mandatory_args = [arg for arg in args if not arg.get("optional")]

    if len(cmd_args) < len(mandatory_args):
        print("Error: Missing args:")
        missing = [arg["name"] for arg in mandatory_args][len(cmd_args):]
        print("\n".join(missing))
        sys.exit(1)

    if len(cmd_args) > len(args):
        print("Error: Too many args")
        sys.exit(1)

print(script_name)
