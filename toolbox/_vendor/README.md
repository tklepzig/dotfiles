# Vendored dependencies

Third-party code copied in verbatim, not installed. `setup_includes.py` puts
this directory on `sys.path` and imports from it, so the toolbox-include merge
has a TOML *writer* without a runtime `pip` dependency on a fresh machine.

## tomli_w (1.2.0)

- Source: https://pypi.org/project/tomli-w/ — `tomli_w/` from the wheel, verbatim.
- License: MIT (see `tomli_w/LICENSE`), © Taneli Hukkinen.
- Why vendored: `tomllib` (stdlib) reads TOML but cannot write it. The only
  structured write in the toolbox is the `_info.toml` merge in
  `setup_includes.py`. Pure Python, zero dependencies, spec-frozen (TOML 1.0.0)
  → effectively write-once; see PORTING.md "DECISION PENDING (8c)".
- Refresh (only if ever needed): `pip download tomli-w==<v> --no-deps`, unzip the
  wheel, replace `tomli_w/`. Keep the LICENSE.

If the vendored copy ever fails to import or dump, `setup_includes.py` falls
back to a `pip install tomli-w` copy, and if that's absent too it soft-skips
only the merge (Plan B).
