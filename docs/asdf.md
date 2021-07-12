Add plugin (e.g. nodejs)

```
asdf plugin add nodejs
```

Install version and add it to `.tool-versions`

```
asdf install nodejs 14.17.1
```

Install version which is listed in `.tool-versions`

```
asdf install nodejs
```

Set local version of plugin (`./.tool-versions`)

```
asdf local nodejs 14.17.1
```

Set global version of plugin (`~/.tool-versions`)

```
asdf global nodejs 14.17.1
```

Reshim plugin to create shims for newly added executables (e.g. after a `pip install`)

```
asdf reshim python
```
