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
| `coc-eslint` | `nvim-lint` + `eslint_d` | Lint + autofix |
| `coc-snippets` | `LuaSnip` + `cmp_luasnip` | Snippet engine |
| jest-snippets + js-snippet-pack | `friendly-snippets` | Community snippet library |
| `coc-emoji` | `hrsh7th/cmp-emoji` | Emoji completion |
| `coc-dictionary` + `coc-word` | `uga-rosa/cmp-dictionary` | Word/dictionary completion |
| `coc-db` | `vim-dadbod-completion` | SQL/DB completion |
| completion popup | `nvim-cmp` | Completion engine |
| completion sources | `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, `cmp-omni` | Completion sources |

---

## Feature Parity

### Completion (`nvim-cmp`)

- LSP completions, snippets, buffer words, file paths, omni
- `<Down>` / `<Up>`: navigate popup (same as before)
- `<Tab>`: confirm selection OR expand/jump snippet (same as before)
- `<S-Tab>`: same as Tab (same as before)
- `<C-x>`: trigger completion manually (same as before)
- Emoji + dictionary sources scoped to `markdown` / `gitcommit` only (same as before)
- SQL/DB completions scoped to `sql`, `mysql`, `plsql` filetypes

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

`nvim-lint` runs `eslint_d` on `BufWritePost` + `InsertLeave` for JS/TS filetypes.

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

| Old (CoC) | New (LSP/cmp) |
|---|---|
| `CocSearch` | `CmpItemAbbrMatch` |
| `CocMenuSel` | `PmenuSel` |
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

## Origin

Current CoC Features → Modern Replacements

1. Core LSP: nvim-lspconfig + mason.nvim

Replaces all your coc-* language servers. Mason handles installing them
automatically.

{ "neovim/nvim-lspconfig" },
{ "williamboman/mason.nvim" },
{ "williamboman/mason-lspconfig.nvim" }, -- bridges the two

Language servers to install via Mason:

┌──────────────────┬────────────────────────────────────┐
│  CoC Extension   │          Mason / LSP name          │
├──────────────────┼────────────────────────────────────┤
│ coc-tsserver     │ ts_ls (typescript-language-server) │
├──────────────────┼────────────────────────────────────┤
│ coc-python       │ pyright                            │
├──────────────────┼────────────────────────────────────┤
│ coc-solargraph   │ solargraph                         │
├──────────────────┼────────────────────────────────────┤
│ coc-sumneko-lua  │ lua_ls                             │
├──────────────────┼────────────────────────────────────┤
│ coc-vimlsp       │ vimls                              │
├──────────────────┼────────────────────────────────────┤
│ coc-css          │ cssls                              │
├──────────────────┼────────────────────────────────────┤
│ coc-json         │ jsonls                             │
├──────────────────┼────────────────────────────────────┤
│ coc-tailwindcss3 │ tailwindcss                        │
└──────────────────┴────────────────────────────────────┘

2. Completion: nvim-cmp

Replaces CoC's completion popup with a composable system:

{ "hrsh7th/nvim-cmp" },
{ "hrsh7th/cmp-nvim-lsp" },    -- LSP source
{ "hrsh7th/cmp-buffer" },       -- buffer words
{ "hrsh7th/cmp-path" },         -- file paths
{ "uga-rosa/cmp-dictionary" },  -- replaces coc-dictionary
{ "hrsh7th/cmp-emoji" },        -- replaces coc-emoji
{ "David-Kunz/cmp-npm" },       -- bonus: npm package completion

For word completion (replaces coc-word): cmp-buffer covers most of it, or add
hrsh7th/cmp-omni.

3. Snippets: LuaSnip + friendly-snippets

Replaces coc-snippets:

{ "L3MON4D3/LuaSnip" },
{ "saadparwaiz1/cmp_luasnip" },     -- nvim-cmp source for LuaSnip
{ "rafamadriz/friendly-snippets" },  -- community snippet collection (includes
jest, JS)

Your jest + JS snippet packs from GitHub are largely covered by
friendly-snippets.

4. Formatting + Linting: conform.nvim + nvim-lint

Replaces coc-prettier + coc-eslint:

{ "stevearc/conform.nvim" },  -- formatOnSave, prettier
{ "mfussenegger/nvim-lint" }, -- ESLint diagnostics + autofix

conform.nvim config to replicate your current behavior:
require("conform").setup({
format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
formatters_by_ft = {
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    css = { "prettierd" },
    -- etc.
},
})

5. Emmet: emmet-language-server

Install via Mason (emmet-language-server), configure in nvim-lspconfig.
Replaces coc-emmet.

6. Diagnostics Statusline

Replace your CocStatus() function using the built-in vim.diagnostic API:
function DiagnosticStatus()
local errors = #vim.diagnostic.get(0, { severity =
vim.diagnostic.severity.ERROR })
-- same logic as your current CocStatus()
end

Or use a statusline plugin like lualine.nvim that has built-in diagnostic
support.

7. Database: already covered

You already have vim-dadbod + vim-dadbod-ui. Just add:
{ "kristijanhusak/vim-dadbod-completion" } -- cmp source

---
Keybinding Equivalents

All your current keybindings (gd, gy, gi, gr, <leader>rr, <leader>i, etc.) map
directly to vim.lsp.buf.* functions — no behavioral change needed, just
different wiring.

---
Recommended Starter: LazyVim or kickstart.nvim

Since you're on lazy.nvim, the easiest path is to look at
https://github.com/nvim-lua/kickstart.nvim — it's a minimal single-file config
that wires up exactly this stack (lspconfig + mason + nvim-cmp + LuaSnip +
conform + nvim-lint). You can cherry-pick the relevant sections into your
existing config.

---
Migration Strategy

1. Remove coc.nvim from nvim-lazy-plugins.lua
2. Add the plugins above incrementally (LSP first, then completion, then
formatting)
3. Port your keybindings in an LspAttach autocmd so they only activate when an
LSP is attached
4. Move CoC-specific settings from vimrc (the set hidden, updatetime, etc. —
most are already good defaults in Neovim)

