#!/usr/bin/env node

import { execSync } from 'node:child_process';
import { existsSync, readdirSync, statSync, symlinkSync, unlinkSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve, basename, extname } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';
import yaml from 'js-yaml';

const TOOLBOX_PATH = dirname(fileURLToPath(import.meta.url));
const DF_LOCAL_PATH = join(homedir(), '.dotfiles-local');
const DOCS_PATH = join(TOOLBOX_PATH, 'docs');
const SCRIPTS_PATH = join(TOOLBOX_PATH, 'scripts');
const INFO_YAML_PATH = join(SCRIPTS_PATH, '_info.yaml');

const NON_BREAKING_HYPHEN = '‑';

function log(message, indent = 0) {
  console.log(`${'  '.repeat(indent)}${message}`);
}

function forceSymlink(source, targetDir) {
  const target = join(targetDir, basename(source));
  if (existsSync(target)) unlinkSync(target);
  symlinkSync(source, target);
}

function linkFiles(sourceDir, targetDir) {
  for (const file of readdirSync(sourceDir)) {
    if (file === '_info.yaml') continue;
    const fullPath = join(sourceDir, file);
    if (!statSync(fullPath).isFile()) continue;
    forceSymlink(fullPath, targetDir);
  }
}

function mergeInfoYaml(includeScriptsPath) {
  const includeInfoPath = join(includeScriptsPath, '_info.yaml');
  if (!existsSync(includeInfoPath)) return;

  log('Merging _info.yaml', 2);
  const existing = yaml.load(readFileSync(INFO_YAML_PATH, 'utf8')) ?? {};
  const incoming = yaml.load(readFileSync(includeInfoPath, 'utf8')) ?? {};
  // Shallow merge: include entries win over base entries with the same key
  writeFileSync(INFO_YAML_PATH, yaml.dump({ ...existing, ...incoming }));
}

function processIncludes() {
  const includesPath = join(DF_LOCAL_PATH, 'toolbox-include.yaml');
  if (!existsSync(includesPath)) return;

  log('Processing includes');
  const includes = yaml.load(readFileSync(includesPath, 'utf8')) ?? [];

  for (const rawPath of includes) {
    const includePath = resolve(DF_LOCAL_PATH, rawPath);
    if (!existsSync(includePath)) continue;

    log(rawPath, 1);

    if (existsSync(join(includePath, '.git'))) {
      log('Found git repo, updating', 2);
      try {
        execSync('git pull --ff-only', { cwd: includePath, stdio: 'pipe' });
      } catch {
        log('Warning: git update failed, continuing', 2);
      }
    }

    const docsSource = join(includePath, 'docs');
    if (existsSync(docsSource)) {
      log('Linking docs', 2);
      linkFiles(docsSource, DOCS_PATH);
    }

    const scriptsSource = join(includePath, 'scripts');
    if (existsSync(scriptsSource)) {
      log('Linking scripts', 2);
      linkFiles(scriptsSource, SCRIPTS_PATH);
      mergeInfoYaml(scriptsSource);
    }
  }
}

function createSection(dirPath, name) {
  if (!existsSync(dirPath)) return { name, entries: [] };

  const entries = readdirSync(dirPath)
    .filter(file => extname(file) === '.md')
    .map(file => basename(file, '.md'))
    .sort((first, second) => first.toLowerCase().localeCompare(second.toLowerCase()));

  return { name, entries };
}

function buildIndexContent(sections) {
  let content = '';

  for (const section of sections.slice(1)) {
    content += `- [${section.name}](#${section.name.toLowerCase()})\n`;
  }

  for (const [index, section] of sections.entries()) {
    const headlinePrefix = index === 0 ? '#' : '##';
    content += `\n${headlinePrefix} ${section.name}\n\n`;
    for (const entry of section.entries) {
      const link = index === 0 ? entry : `${section.name}/${entry}`;
      const label = entry.replace(/--+/g, NON_BREAKING_HYPHEN).replace(/-/g, ' ');
      content += `- [${label}](${link})\n`;
    }
  }

  return content;
}

function updateServiceWorkerCache(sections) {
  const swPath = join(DOCS_PATH, '_app', 'public', 'sw.js');
  if (!existsSync(swPath)) return;

  const cacheEntries = sections.flatMap((section, index) =>
    section.entries.map(entry => {
      const link = index === 0 ? entry : `${section.name}/${entry}`;
      return `/${link}`;
    })
  );

  const content = readFileSync(swPath, 'utf8');
  const updated = content.replace(
    /const docsCache = \[.*?\];/s,
    `const docsCache = ${JSON.stringify(cacheEntries)};`
  );
  if (updated === content) throw new Error('sw.js: docsCache pattern not found — cache not updated');
  writeFileSync(swPath, updated);
}

function writeDocsIndex() {
  log('Writing docs index');

  const indexPath = join(DOCS_PATH, 'index.md');

  const toolboxSection = createSection(DOCS_PATH, 'Toolbox');
  const subSections = readdirSync(DOCS_PATH)
    .filter(name => {
      if (name.startsWith('_')) return false;
      return statSync(join(DOCS_PATH, name)).isDirectory();
    })
    .map(name => createSection(join(DOCS_PATH, name), name));

  const sections = [toolboxSection, ...subSections];

  writeFileSync(indexPath, buildIndexContent(sections));
  updateServiceWorkerCache(sections);
}

log('Setting up toolbox');
processIncludes();
writeDocsIndex();
