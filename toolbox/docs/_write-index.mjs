#!/usr/bin/env node

import { readdir, readFile, writeFile, rm } from "fs/promises";
import { fileURLToPath } from "url";
import path from "path";

const docsDir = fileURLToPath(new URL(".", import.meta.url));
const indexPath = path.join(docsDir, "index.md");
const serviceWorkerPath = path.join(docsDir, "_app", "public", "sw.js");

const NON_BREAKING_HYPHEN = "‑";

const localeIndependentCompare = (first, second) =>
  first < second ? -1 : first > second ? 1 : 0;

const caseInsensitiveCompare = (first, second) =>
  localeIndependentCompare(first.toLowerCase(), second.toLowerCase());

const createSection = async (dirPath, name) => {
  const dirEntries = await readdir(dirPath, { withFileTypes: true });
  const entries = dirEntries
    .filter(
      (entry) =>
        entry.isFile() &&
        !entry.name.startsWith(".") &&
        entry.name.endsWith(".md"),
    )
    .map((entry) => path.basename(entry.name, path.extname(entry.name)))
    .sort(caseInsensitiveCompare);

  return { name, entries };
};

const collectSections = async () => {
  await rm(indexPath, { force: true });

  const toolbox = await createSection(docsDir, "Toolbox");

  const dirEntries = await readdir(docsDir, { withFileTypes: true });
  const subDirNames = dirEntries
    .filter(
      (entry) =>
        entry.isDirectory() &&
        !entry.name.startsWith("_") &&
        !entry.name.startsWith("."),
    )
    .map((entry) => entry.name)
    .sort(localeIndependentCompare);

  const subSections = await Promise.all(
    subDirNames.map((name) => createSection(path.join(docsDir, name), name)),
  );

  return [toolbox, ...subSections];
};

const renderIndex = (sections) => {
  const indexLinks =
    sections.length === 1
      ? "-\n"
      : sections
          .slice(1)
          .map(
            (section) =>
              `- [${section.name}](#${section.name.toLowerCase()})\n`,
          )
          .join("");

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

const writeCache = async (sections) => {
  const cacheEntries = sections.flatMap((section, index) =>
    section.entries.map(
      (entry) => `/${index === 0 ? entry : `${section.name}/${entry}`}`,
    ),
  );

  const content = await readFile(serviceWorkerPath, "utf-8");
  const cacheArray = `[${cacheEntries.map((entry) => JSON.stringify(entry)).join(", ")}]`;
  const replacement = `const docsCache = ${cacheArray};`;
  const updatedContent = content.replace(
    /const docsCache = \[.*\];/g,
    () => replacement,
  );

  await writeFile(serviceWorkerPath, updatedContent);
};

const sections = await collectSections();
await writeFile(indexPath, renderIndex(sections));
await writeCache(sections);
