To update all packages to a new major version, install the npm-check-updates package globally:

```
npm install -g npm-check-updates
```

Then run it:

```
ncu -u
```

This will upgrade all the version hints in the package.json file, to dependencies and devDependencies, so npm can install the new major version.

You are now ready to run the update:

```
npm update 
```
(Or if you freshly cloned the repo `npm install`)

---

> #### For reference
>
> - `npm update` will update the packages according to their version regex
> - `npm outdated` show a list which packages are out of date
