#!/usr/bin/env node

// Regenerate the toolbox docs index (index.md) and the service-worker cache.
//
// The docs tree is one flat directory of `*.md` files (the "Toolbox" section)
// plus optional sub-directories, each its own section. We emit a top-of-page
// link list, then a heading + bullet list per section, and finally rewrite the
// `docsCache` array the PWA service worker uses for offline caching.

import { readdir, readFile, writeFile, rm } from "fs/promises";
import { fileURLToPath } from "url";
import path from "path";

const docsDir = fileURLToPath(new URL(".", import.meta.url));
const indexPath = path.join(docsDir, "index.md");
const serviceWorkerPath = path.join(docsDir, "_app", "public", "sw.js");

// U+2011 NON-BREAKING HYPHEN. A "--" in a slug means "render a literal hyphen"
// (e.g. a compound name), so it must survive the "- becomes space" pass below.
const NON_BREAKING_HYPHEN = "‑";

// Stable code-unit order (the default for `<` on strings), not locale-aware
// collation (localeCompare), which would reorder some entries.
const codePointCompare = (first, second) =>
  first < second ? -1 : first > second ? 1 : 0;

const caseInsensitiveCompare = (first, second) =>
  codePointCompare(first.toLowerCase(), second.toLowerCase());

// A section: its display name and its entry slugs (basename, no ext), sorted
// case-insensitively.
const createSection = async (dirPath, name) => {
  const dirEntries = await readdir(dirPath, { withFileTypes: true });
  const entries = dirEntries
    .filter(
      (entry) =>
        entry.isFile() && !entry.name.startsWith(".") && entry.name.endsWith(".md")
    )
    .map((entry) => path.basename(entry.name, path.extname(entry.name)))
    .sort(caseInsensitiveCompare);

  return { name, entries };
};

// The Toolbox section followed by one section per non-underscore sub-dir.
const collectSections = async () => {
  // Delete index.md before globbing so the freshly-read Toolbox section can't
  // pick up the file we're about to regenerate — without this, a second run
  // would emit a stray "- [index](index)" entry.
  await rm(indexPath, { force: true });

  const toolbox = await createSection(docsDir, "Toolbox");

  // Sub-directories only, skipping "_"-prefixed (infra) and dot-dirs. Sorted by
  // name case-sensitively — distinct from the case-insensitive entry sort above.
  const dirEntries = await readdir(docsDir, { withFileTypes: true });
  const subDirNames = dirEntries
    .filter(
      (entry) =>
        entry.isDirectory() &&
        !entry.name.startsWith("_") &&
        !entry.name.startsWith(".")
    )
    .map((entry) => entry.name)
    .sort(codePointCompare);

  const subSections = await Promise.all(
    subDirNames.map((name) => createSection(path.join(docsDir, name), name))
  );

  return [toolbox, ...subSections];
};

// The full index.md text: the top link list, then a section per heading.
const renderIndex = (sections) => {
  // A single section (no sub-dirs) gets a bare "-" placeholder; otherwise an
  // in-page anchor link per sub-section.
  const indexLinks =
    sections.length === 1
      ? "-\n"
      : sections
          .slice(1)
          .map((section) => `- [${section.name}](#${section.name.toLowerCase()})\n`)
          .join("");

  // The first (Toolbox) section is an h1 with bare-slug links; sub-sections are
  // h2 with "Name/slug" links.
  const sectionBlocks = sections
    .map((section, index) => {
      const headlinePrefix = index === 0 ? "#" : "##";
      const heading = `\n${headlinePrefix} ${section.name}\n\n`;
      const bullets = section.entries
        .map((entry) => {
          const link = index === 0 ? entry : `${section.name}/${entry}`;
          const label = entry
            .replaceAll("--", NON_BREAKING_HYPHEN)
            .replaceAll("-", " ");
          return `- [${label}](${link})\n`;
        })
        .join("");
      return heading + bullets;
    })
    .join("");

  return indexLinks + sectionBlocks;
};

// Rewrite the service worker's docsCache array with every doc's path.
const writeCache = async (sections) => {
  const cacheEntries = sections.flatMap((section, index) =>
    section.entries.map(
      (entry) => `/${index === 0 ? entry : `${section.name}/${entry}`}`
    )
  );

  const content = await readFile(serviceWorkerPath, "utf-8");
  // Build the array by hand for ", "-separated entries — JSON.stringify on the
  // whole array omits the spaces. Pass a function as the replacement so "$"/"\"
  // in the array text aren't read as replacement patterns. No /s flag, so "."
  // won't span past the single docsCache line.
  const cacheArray = `[${cacheEntries.map((entry) => JSON.stringify(entry)).join(", ")}]`;
  const replacement = `const docsCache = ${cacheArray};`;
  const updatedContent = content.replace(
    /const docsCache = \[.*\];/g,
    () => replacement
  );

  await writeFile(serviceWorkerPath, updatedContent);
};

const sections = await collectSections();
await writeFile(indexPath, renderIndex(sections));
await writeCache(sections);
