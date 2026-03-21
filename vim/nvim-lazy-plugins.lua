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
          -- Formatters
          "prettierd",
          "stylua",
          -- Linters
          "eslint_d",
        },
        auto_update = false,
        run_on_start = true,
      })

      require("mason-lspconfig").setup({
        automatic_installation = false,
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

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
  -- Completion: nvim-cmp
  -- =========================================================
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-omni" },
      { "hrsh7th/cmp-emoji" },           -- replaces coc-emoji
      { "uga-rosa/cmp-dictionary" },     -- replaces coc-dictionary / coc-word
      { "L3MON4D3/LuaSnip" },
      { "saadparwaiz1/cmp_luasnip" },
      { "rafamadriz/friendly-snippets" }, -- includes jest + JS snippets
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load VSCode-style snippets from friendly-snippets (jest, JS, etc.)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Dictionary source: /usr/share/dict/words for prose filetypes
      require("cmp_dictionary").setup({
        paths = { "/usr/share/dict/words" },
        first_case_insensitive = true,
        document = { enable = false },
      })

      cmp.setup({
        preselect = cmp.PreselectMode.Item, -- replaces suggest.noselect: false

        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          -- Navigate popup (mirrors existing <Down>/<Up> CoC mappings)
          ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
          ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),

          -- <Tab>: confirm selection OR expand/jump snippet (mirrors CoC Tab logic)
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          -- <S-Tab>: same as Tab (mirrors CoC S-Tab)
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),

          -- <C-x>: trigger completion manually (mirrors CoC <c-x>)
          ["<C-x>"] = cmp.mapping.complete(),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
          { name = "omni" },
        }),
      })

      -- Emoji + dictionary only for markdown / gitcommit (mirrors coc-settings filetypes)
      cmp.setup.filetype({ "markdown", "gitcommit" }, {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "emoji" },
          { name = "dictionary", keyword_length = 3 },
          { name = "buffer" },
        }),
      })

      -- vim-dadbod completion for SQL buffers
      cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
        sources = cmp.config.sources({
          { name = "vim-dadbod-completion" },
          { name = "buffer" },
        }),
      })
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

  -- =========================================================
  -- Linting: nvim-lint (replaces coc-eslint)
  -- =========================================================
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript      = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript      = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      }

      -- Run linter on save and after leaving insert (mirrors eslint.autoFixOnSave)
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
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
