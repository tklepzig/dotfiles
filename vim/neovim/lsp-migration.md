# CoC → Native LSP Migration (PoC)

Branch: `poc/lsp-migration`

## Overview

Replaces `coc.nvim` (and all `coc-*` extensions) with the modern Neovim native LSP
stack. Everything that CoC provided is covered by focused, composable plugins.

---

## Plugin Replacements

| CoC | Replacement | Role |
|---|---|---|
| `coc.nvim` core | `nvim-lspconfig` | LSP client configuration |
| – | `mason.nvim` | Install/manage LSP servers & tools |
| – | `mason-lspconfig.nvim` | Bridge mason ↔ lspconfig |
| – | `mason-tool-installer.nvim` | Auto-install formatters/linters |
| `coc-tsserver` | `typescript-language-server` (mason) | JS/TS LSP |
| `coc-python` | `pyright` (mason) | Python LSP |
| `coc-solargraph` | `solargraph` (mason) | Ruby LSP |
| `coc-sumneko-lua` | `lua-language-server` (mason) | Lua LSP |
| `coc-vimlsp` | `vim-language-server` (mason) | VimL LSP |
| `coc-css` / `coc-styled-components` | `css-lsp` (mason) | CSS/SCSS LSP |
| `coc-json` | `json-lsp` (mason) | JSON LSP |
| `coc-tailwindcss3` | `tailwindcss-language-server` (mason) | Tailwind LSP |
| `coc-emmet` | `emmet-language-server` (mason) | Emmet expansion |
| `coc-prettier` | `conform.nvim` + `prettierd` | Format on save |
| `coc-eslint` | `eslint-lsp` (vscode-eslint, mason) | Lint diagnostics + code actions + fix on save |
| `coc-snippets` | `LuaSnip` (+ `friendly-snippets`) | Snippet engine + content |
| jest-snippets + js-snippet-pack | `friendly-snippets` | Community snippet library |
| `coc-emoji` | `hrsh7th/cmp-emoji` (via `blink.compat`) | Emoji completion |
| `coc-dictionary` + `coc-word` | `uga-rosa/cmp-dictionary` (via `blink.compat`) | Word/dictionary completion |
| `coc-db` | `vim-dadbod-completion` (via `blink.compat`) | SQL/DB completion |
| completion popup | `blink.cmp` | Completion engine (built-in lsp/buffer/path/snippets sources) |

---

## Feature Parity

### Completion (`blink.cmp`)

- LSP completions, snippets, buffer words, file paths — all built-in sources, no extra cmp-* deps
- Rust-backed fuzzy matcher (prebuilt binary via `version = "*"`, no toolchain required)
- `<Down>` / `<Up>`: navigate popup (same as before)
- `<Tab>`: accept selection OR jump forward in active snippet (same as before)
- `<S-Tab>`: accept selection OR jump backward in active snippet (same as before)
- `<C-x>`: trigger completion manually (same as before)
- Emoji + dictionary sources scoped to `markdown` / `gitcommit` only — wired via `blink.compat` since these don't have native blink sources
- SQL/DB completions scoped to `sql`, `mysql`, `plsql` filetypes (also via `blink.compat`)

### LSP Keybindings (unchanged)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `<leader>K` | Previous diagnostic |
| `<leader>J` | Next diagnostic |
| `<leader>i` | Hover documentation |
| `<leader>rr` | Rename symbol |
| `<leader>a` | Code action (normal + visual) |
| `<leader>ac` | Code action (current line) |
| `<leader>.` | Apply preferred quick-fix |

### Commands (same names)

| Command | Action |
|---|---|
| `:Format` | Format current buffer (via conform.nvim) |
| `:OR` | Organize imports (via LSP code action) |
| `:Fold` | Fold via LSP |

### Format on save

`conform.nvim` with `format_on_save` enabled — covers JS/TS/CSS/JSON/Markdown/
HTML/YAML/Ruby/Lua. Falls back to LSP formatting when no formatter is configured.

### ESLint auto-fix on save

`eslint-lsp` (`vscode-eslint-language-server`) provides diagnostics, code actions
and the `EslintFixAll` command. Fix-on-save is wired via an `LspAttach` autocmd
that registers `EslintFixAll` on `BufWritePre` for buffers where the eslint LSP
attaches — replicating the old `editor.codeActionsOnSave: source.fixAll.eslint`.

**Ordering caveat:** `conform.nvim`'s `format_on_save` and the eslint
`BufWritePre` autocmd both fire on save. `conform` registers at startup;
the eslint autocmd registers per-buffer at LspAttach — so `prettier` runs
*before* eslint's fix-all. In repos that use `eslint-config-prettier` (i.e. eslint
disables formatting rules and lets prettier own them) this is fine. If your
eslint and prettier configs disagree on style, you'll see the order matter and
need a custom save hook.

### Symbol highlight under cursor

`LspAttach` autocmd wires `vim.lsp.buf.document_highlight` to `CursorHold` when
the server supports `textDocument/documentHighlight`.

### Diagnostic float

`CursorHold` opens a floating diagnostic window (`vim.diagnostic.open_float`),
replacing CoC's inline diagnostic messages.

### Statusline

`LspStatus()` replaces `CocStatus()` — shows error count and first error line
using `vim.diagnostic.get()`.

### Highlights

| Old (CoC) | New (LSP/blink) |
|---|---|
| `CocSearch` | `BlinkCmpLabelMatch` |
| `CocMenuSel` | `BlinkCmpMenuSelection` (or `PmenuSel`) |
| `CocUnusedHighlight` | `DiagnosticUnnecessary` |
| `CocHighlightText` | `LspReferenceText` / `LspReferenceRead` / `LspReferenceWrite` |

---

## Files Changed

- `vim/nvim-lazy-plugins.lua` — removed `coc.nvim`, added all replacement plugins
- `vim/neovim/vimrc` — replaced CoC settings block with LSP equivalents
- `vim/neovim/mappings.vim` — replaced CoC keybindings with `vim.lsp.buf.*` calls
- `vim/neovim/statusline.vim` — replaced `CocStatus()` with `LspStatus()`
- `vim/vim/highlight-overrides.vim` — replaced CoC highlights with LSP/cmp ones
- `vim/neovim/install.rb` — removed `coc-settings.json` symlinks

---

## First-run Notes

On first launch, `mason-tool-installer` auto-installs all LSP servers, formatters,
and linters. This requires internet access and takes a minute or two.

Progress can be monitored with `:Mason`.

Manually installed tools (if not via Mason): `rubocop` (gem), `prettierd`/`prettier`
(npm global or project-local).

---

## Notes on follow-up swaps (post-initial PoC)

The first iteration used `nvim-cmp` (with cmp-* sources) and `nvim-lint` +
`eslint_d`. Both have since been replaced:

- **`nvim-cmp` → `blink.cmp`.** `nvim-cmp` is effectively unmaintained
  upstream. `blink.cmp` provides built-in `lsp` / `buffer` / `path` / `snippets`
  sources (so the cmp-nvim-lsp / cmp-buffer / cmp-path / cmp-omni / cmp_luasnip
  zoo collapses into one plugin), a Rust-backed fuzzy matcher (prebuilt binary
  via `version = "*"`, no Rust toolchain on the user's machine), and simpler
  keymap config. cmp-only sources we still need (`cmp-emoji`, `cmp-dictionary`,
  `vim-dadbod-completion`) are wired through `blink.compat`.

- **`nvim-lint` + `eslint_d` → `eslint-lsp` (vscode-eslint).** ESLint is a
  language server upstream, so running it through `nvim-lint` is wrapping a
  language server in a non-LSP shim. Using `eslint-lsp` directly gives us
  diagnostics, code actions, and `EslintFixAll` for free, and removes the
  `nvim-lint` plugin entirely. This is what `coc-eslint` was wrapping under
  the hood.
