# How to handle different nppm logins on one machine

## Approach 1: Using an ignored `.npmrc` file

1. In each project's `.gitignore` (and `.npmignore` for NPM modules) add this line: `.npmrc`. This will make sure you never commit (or publish) the `.npmrc` file.
2. In each project's folder create `.npmrc` file containing this: `//registry.npmjs.org/:_authToken=11111111-1111-1111-1111-111111111111` (replace the GUID with an actual NPM auth token, e.g. you can grab it from `~/.npmrc`)

> The npm CLI will look in your current folder for the `.npmrc` file (or in any parent folder) and will use it for auth.

## Approach 2: Using an environment variable

1. Make sure `.npmrc` is NOT present in `.gitignore` (which is common for most projects out there)
2. Create the `.npmrc` file in the root folder of your project. Put this inside: `//registry.npmjs.org/:\_authToken=${NPM_TOKEN}`. This will make `npm` to use `NPM_TOKEN` env var. And `npm` will abort if it not exists.
3. Commit and push that file.
4. Make sure your shell has the `NPM_TOKEN` environment variable set. E.g. `NPM_TOKEN=11111111-1111-1111-1111-111111111111`.

> All the projects, which have this file committed, will use your environment variable NPM_TOKEN for npm auth.

#### Either way, as the result all `npm` commands work as is, no need to pass `--userconfig` or anything.

## Check which user is currently used

```
npm whoami
```
