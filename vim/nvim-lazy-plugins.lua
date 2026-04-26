return {
  -- base (shared with vim profile)
  { "tomasiser/vim-code-dark" },
  { "christoomey/vim-tmux-navigator" },
  { "mbbill/undotree" },
  { "rafi/awesome-vim-colorschemes" },

  -- general
  { "godlygeek/tabular" },
  { "fladson/vim-kitty" },
  { "scrooloose/nerdtree" },
  { "Xuyuanp/nerdtree-git-plugin" },
  { "PhilRunninger/nerdtree-visual-selection" },
  { "tpope/vim-fugitive" },
  { "junegunn/gv.vim" },
  { "airblade/vim-gitgutter" },
  { "scrooloose/nerdcommenter" },
  { "sheerun/vim-polyglot", commit = "4d4aa5fe553a47ef5c5c6d0a97bb487fdfda2d5b" },
  { "tpope/vim-surround" },
  { "jiangmiao/auto-pairs" },
  { "dyng/ctrlsf.vim" },
  { "Yggdroot/indentLine" },
  { "benmills/vimux" },
  { "junegunn/fzf", build = function() vim.fn["fzf#install"]() end },
  { "junegunn/fzf.vim" },
  { "tklepzig/vim-buffer-navigator" },
  { "tpope/vim-abolish" },
  { "mracos/mermaid.vim" },
  { "markonm/traces.vim" },
  { "github/copilot.vim" },
  { "wellle/context.vim" },
  { "samoshkin/vim-mergetool" },
  { "rhysd/conflict-marker.vim" },
  { "HerringtonDarkholme/yats.vim" },
  { "alvan/vim-closetag" },
  { "janko/vim-test" },
  { "thinca/vim-themis" },

  -- markdown & Co
  { "junegunn/goyo.vim" },
  { "junegunn/seoul256.vim" },
  { "junegunn/limelight.vim" },
  { "plasticboy/vim-markdown" },
  { "mzlogin/vim-markdown-toc" },
  { "tklepzig/vim-markdown-navigator" },
  { "lervag/vimtex" },

  -- ruby
  { "vim-ruby/vim-ruby" },
  { "tpope/vim-rails" },
  { "tpope/vim-bundler" },
  { "tpope/vim-rake" },
  { "tpope/vim-projectionist" },
  { "tpope/vim-dadbod" },
  { "kristijanhusak/vim-dadbod-ui" },
  { "kristijanhusak/vim-dadbod-completion" },

  -- neovim-specific
  { "nvim-lua/plenary.nvim" },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- =========================================================
  -- LSP: Mason (installer) + lspconfig
  -- =========================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
    },
    config = function()
      require("mason").setup()

      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSP servers
          "typescript-language-server",
          "pyright",
          "solargraph",
          "lua-language-server",
          "vim-language-server",
          "css-lsp",
          "json-lsp",
          "tailwindcss-language-server",
          "emmet-language-server",
          "eslint-lsp",
          -- Formatters
          "prettierd",
          "stylua",
        },
        auto_update = false,
        run_on_start = true,
      })

      require("mason-lspconfig").setup({
        automatic_installation = false,
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Simple servers with default config
      for _, server in ipairs({ "pyright", "vimls" }) do
        lspconfig[server].setup({ capabilities = capabilities })
      end

      -- TypeScript / JavaScript
      lspconfig.ts_ls.setup({ capabilities = capabilities })

      -- CSS (includes scss, less)
      lspconfig.cssls.setup({ capabilities = capabilities })

      -- JSON with chrome manifest schema
      lspconfig.jsonls.setup({
        capabilities = capabilities,
        settings = {
          json = {
            schemas = {
              {
                fileMatch = { "manifest.json" },
                url = "https://json.schemastore.org/chrome-manifest.json",
              },
            },
          },
        },
      })

      -- TailwindCSS with CVA (Class Variance Authority) support
      lspconfig.tailwindcss.setup({
        capabilities = capabilities,
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
              },
            },
          },
        },
      })

      -- Emmet (HTML/JSX expanding)
      lspconfig.emmet_language_server.setup({ capabilities = capabilities })

      -- ESLint (vscode-eslint LSP) — diagnostics + code actions + fix-on-save
      lspconfig.eslint.setup({
        capabilities = capabilities,
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })

      -- Ruby (Solargraph)
      lspconfig.solargraph.setup({
        capabilities = capabilities,
        settings = {
          solargraph = {
            formatting = true,
            autoformat = true,
            hover = true,
            diagnostics = true,
            transport = "stdio",
          },
        },
      })

      -- Lua (with Neovim runtime awareness)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
          },
        },
      })

      -- Document highlight on CursorHold (replaces CoC's CursorHold highlight)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.supports_method("textDocument/documentHighlight") then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = args.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              buffer = args.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  -- =========================================================
  -- Completion: blink.cmp (replaces nvim-cmp + cmp-* sources)
  -- =========================================================
  {
    "saghen/blink.cmp",
    version = "*", -- use prebuilt fuzzy-matcher binary; no Rust toolchain needed
    dependencies = {
      { "saghen/blink.compat", version = "*", lazy = true, opts = {} },
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" }, -- includes jest + JS snippets
      { "hrsh7th/cmp-emoji" },             -- via blink.compat
      { "uga-rosa/cmp-dictionary" },       -- via blink.compat
    },
    opts = {
      keymap = {
        preset = "none",
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        -- <Tab>: accept selection OR jump forward in snippet (mirrors CoC Tab logic)
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        -- <S-Tab>: accept selection OR jump backward in snippet
        ["<S-Tab>"] = { "select_and_accept", "snippet_backward", "fallback" },
        -- <C-x>: trigger completion manually
        ["<C-x>"] = { "show", "fallback" },
      },

      snippets = { preset = "luasnip" },

      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
      },

      sources = {
        default = { "lsp", "snippets", "path", "buffer" },
        per_filetype = {
          markdown = { "lsp", "snippets", "emoji", "dictionary", "buffer" },
          gitcommit = { "lsp", "snippets", "emoji", "dictionary", "buffer" },
          sql = { "dadbod", "buffer" },
          mysql = { "dadbod", "buffer" },
          plsql = { "dadbod", "buffer" },
        },
        providers = {
          emoji = {
            name = "emoji",
            module = "blink.compat.source",
          },
          dictionary = {
            name = "dictionary",
            module = "blink.compat.source",
            min_keyword_length = 3,
          },
          dadbod = {
            name = "vim-dadbod-completion",
            module = "blink.compat.source",
          },
        },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    config = function(_, opts)
      -- friendly-snippets: load VSCode-style snippets into LuaSnip
      require("luasnip.loaders.from_vscode").lazy_load()

      -- cmp-dictionary needs setup with paths even when used via blink.compat
      require("cmp_dictionary").setup({
        paths = { "/usr/share/dict/words" },
        first_case_insensitive = true,
        document = { enable = false },
      })

      require("blink.cmp").setup(opts)
    end,
  },

  -- =========================================================
  -- Formatting: conform.nvim (replaces coc-prettier)
  -- =========================================================
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
        formatters_by_ft = {
          javascript      = { "prettierd", "prettier" },
          javascriptreact = { "prettierd", "prettier" },
          typescript      = { "prettierd", "prettier" },
          typescriptreact = { "prettierd", "prettier" },
          css             = { "prettierd", "prettier" },
          scss            = { "prettierd", "prettier" },
          json            = { "prettierd", "prettier" },
          markdown        = { "prettierd", "prettier" },
          html            = { "prettierd", "prettier" },
          yaml            = { "prettierd", "prettier" },
          ruby            = { "rubocop" },
          lua             = { "stylua" },
        },
      })

      -- :Format command (mirrors CoC's :Format)
      vim.api.nvim_create_user_command("Format", function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end, {})
    end,
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      require("CopilotChat").setup({
        mappings = {
          complete = "<C-x>",
          reset = "<leader>cr",
          accept_diff = "<leader>ca"
        }
      })

      vim.api.nvim_create_user_command("CC", function(opts)
        vim.cmd("CopilotChat " .. opts.args)
      end, { range = true, nargs = "*" })

      vim.api.nvim_create_user_command("CT", function(opts)
        vim.cmd("CopilotTests " .. opts.args)
      end, { range = true, nargs = "*" })
    end,
  },

  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = "bundled_build.lua",
    config = function()
      require("mcphub").setup({
        use_bundled_binary = true,
      })
    end,
  },

  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
    config = function()
      require("codecompanion").setup({
        extensions = {
          mcphub = {
            callback = "mcphub.extensions.codecompanion",
            opts = {
              --make_vars = true,
              --temp. workaround, see https://github.com/ravitemer/mcphub.nvim/issues/275
              make_vars = false,
              make_slash_commands = true,
              show_result_in_chat = true
            }
          }
        }
      })
    end,
  },
}
