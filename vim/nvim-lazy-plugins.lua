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
  { "neoclide/coc.nvim", branch = "release" },
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

  -- neovim-specific
  { "nvim-lua/plenary.nvim" },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
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
