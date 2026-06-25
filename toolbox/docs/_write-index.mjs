#!/usr/bin/env node

import { readdir, readFile, writeFile, rm, stat } from "fs/promises";
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

// Toolbox includes are symlinked into the docs tree by setup_includes.py, so we
// must resolve the symlink target's type rather than rely on Dirent (which uses
// lstat semantics and reports every symlink as neither file nor directory).
// stat() follows the link; a broken/vanished link rejects, which we treat as a
// non-match. Resolving the target also routes a symlinked .md *file* to the
// Toolbox section instead of letting readdir() crash on it as a fake subdir.
const isFile = async (entryPath) => {
  try {
    return (await stat(entryPath)).isFile();
  } catch {
    return false;
  }
};

const isDirectory = async (entryPath) => {
  try {
    return (await stat(entryPath)).isDirectory();
  } catch {
    return false;
  }
};

const createSection = async (dirPath, name) => {
  const dirEntries = await readdir(dirPath);
  const markdownFiles = await Promise.all(
    dirEntries
      .filter(
        (entryName) => !entryName.startsWith(".") && entryName.endsWith(".md"),
      )
      .map(async (entryName) => ({
        entryName,
        file: await isFile(path.join(dirPath, entryName)),
      })),
  );
  const entries = markdownFiles
    .filter(({ file }) => file)
    .map(({ entryName }) => path.basename(entryName, path.extname(entryName)))
    .sort(caseInsensitiveCompare);

  return { name, entries };
};

const collectSections = async () => {
  await rm(indexPath, { force: true });

  const toolbox = await createSection(docsDir, "Toolbox");

  const dirEntries = await readdir(docsDir);
  const subDirs = await Promise.all(
    dirEntries
      .filter(
        (entryName) => !entryName.startsWith("_") && !entryName.startsWith("."),
      )
      .map(async (entryName) => ({
        entryName,
        directory: await isDirectory(path.join(docsDir, entryName)),
      })),
  );
  const subDirNames = subDirs
    .filter(({ directory }) => directory)
    .map(({ entryName }) => entryName)
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
