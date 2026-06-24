#!/usr/bin/env node
// Migrate a toolbox `scripts/_info.yaml` to `scripts/_info.toml`.
//
// One-off helper for repos pulled in via `~/.dotfiles-local/toolbox-include.toml`.
// The dotfiles toolbox reader (`_run.py`) consumes TOML now, so an include repo
// that still ships a YAML `_info` needs converting once. This is throwaway: run
// it in the external repo, commit the resulting `_info.toml`, delete the YAML.
//
//   npm i js-yaml        # the only dependency (no built-in YAML reader in Node)
//   node migrate-info-to-toml.js scripts/_info.yaml [scripts/_info.toml]
//
// Output need not byte-match a hand-authored file — it only has to be valid TOML
// that Python's `tomllib` reads back to the same data. The setup merge
// re-serializes anyway.

const fs = require("fs");
const path = require("path");

let yaml;
try {
  yaml = require("js-yaml");
} catch {
  console.error("Missing dependency. Run:  npm i js-yaml");
  process.exit(1);
}

// TOML bare keys allow A-Z a-z 0-9 _ - ; anything else must be quoted.
const BARE_KEY = /^[A-Za-z0-9_-]+$/;

function formatKey(key) {
  return BARE_KEY.test(key) ? key : formatBasicString(key);
}

function formatBasicString(value) {
  const escaped = value
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\t/g, "\\t")
    .replace(/\r/g, "\\r");
  return `"${escaped}"`;
}

function formatString(value) {
  if (!value.includes("\n")) {
    return formatBasicString(value);
  }
  // Multiline: prefer a literal '''…''' block (no escaping, readable, matches
  // the hand-authored style) when the content can't break out of it.
  const literalSafe = !value.includes("'''") && !value.endsWith("'");
  if (literalSafe) {
    // A newline straight after the opening ''' is trimmed by TOML, so this
    // round-trips to exactly `value`.
    return `'''\n${value}'''`;
  }
  // Fallback: basic multiline keeps literal newlines but escapes \ and ".
  const escaped = value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  return `"""\n${escaped}"""`;
}

function formatScalar(value) {
  if (typeof value === "string") return formatString(value);
  if (typeof value === "boolean") return value ? "true" : "false";
  if (typeof value === "number") return String(value);
  throw new Error(`Unsupported scalar value: ${JSON.stringify(value)}`);
}

function formatValue(value) {
  return Array.isArray(value) ? `[${value.map(formatScalar).join(", ")}]` : formatScalar(value);
}

// Skip null/undefined entirely — TOML has no null type, so an empty `optional:`
// or `default:` in the source YAML becomes an absent key, not a broken value.
function isPresent(value) {
  return value !== null && value !== undefined;
}

function emitEntry(name, entry) {
  const lines = [`[${formatKey(name)}]`];
  // Parent-level scalars/arrays (help, completion) MUST precede any
  // [[name.args]] sub-table — once a sub-table opens, bare keys bind to it.
  for (const [key, value] of Object.entries(entry)) {
    if (key === "args" || !isPresent(value)) continue;
    lines.push(`${formatKey(key)} = ${formatValue(value)}`);
  }
  for (const arg of entry.args || []) {
    lines.push(`[[${formatKey(name)}.args]]`);
    for (const [key, value] of Object.entries(arg)) {
      if (!isPresent(value)) continue;
      lines.push(`${formatKey(key)} = ${formatValue(value)}`);
    }
  }
  return lines.join("\n");
}

function convert(data) {
  return Object.entries(data).map(([name, entry]) => emitEntry(name, entry)).join("\n\n") + "\n";
}

function main() {
  const inputPath = process.argv[2];
  if (!inputPath) {
    console.error("Usage: node migrate-info-to-toml.js <_info.yaml> [<_info.toml>]");
    process.exit(1);
  }
  const outputPath = process.argv[3] || path.join(path.dirname(inputPath), "_info.toml");
  const data = yaml.load(fs.readFileSync(inputPath, "utf8")) || {};
  fs.writeFileSync(outputPath, convert(data));
  console.error(`Wrote ${outputPath} (${Object.keys(data).length} entries)`);
}

main();
