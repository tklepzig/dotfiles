return {
  -- base (shared with vim profile)
  { "tomasiser/vim-code-dark" },
  { "christoomey/vim-tmux-navigator" },
  { "mbbill/undotree" },
  { "rafi/awesome-vim-colorschemes" },

  -- general
  { "godlygeek/tabular" },
  { "fladson/vim-kitty" },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      local is_zoomed = false

      require("nvim-tree").setup({
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "A", function()
            if is_zoomed then
              api.tree.resize({ width = 50 })
              is_zoomed = false
            else
              api.tree.resize({ width = vim.o.columns })
              is_zoomed = true
            end
          end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
        end,
        filters = {
          git_ignored = true,
          dotfiles = false,
        },
        view = {
          width = 50,
        },
        actions = {
          open_file = {
            quit_on_open = true,
          },
        },
        renderer = {
          group_empty = false,
          special_files = {},
          icons = {
            show = {
              file = false,
              folder = false,
              folder_arrow = true,
              git = true,
            },
            glyphs = {
              git = {
                unstaged  = "✹",
                staged    = "✚",
                untracked = "✭",
                renamed   = "➜",
                unmerged  = "═",
                deleted   = "✖",
                ignored   = "☒",
              },
            },
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NvimTree",
        callback = function()
          vim.cmd([[
            hi! NvimTreeImageFile ctermfg=211  ctermbg=NONE guifg=#f48fb1 guibg=NONE
            hi! NvimTreeExecFile  ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
            syn match NvimTreeFileImg   #\zs.*\.\(svg\|png\|jpg\|jpeg\|gif\|ico\|webp\)$#
            syn match NvimTreeFileMd    #\zs.*\.mdx\?$#
            syn match NvimTreeFileYml   #\zs.*\.yml$#
            syn match NvimTreeFileJson  #\zs.*\.json$#
            syn match NvimTreeFileHtml  #\zs.*\.html$#
            syn match NvimTreeFileCss   #\zs.*\.css$#
            syn match NvimTreeFileJs    #\zs.*\.js$#
            syn match NvimTreeFileTs    #\zs.*\.tsx\?$#
            syn match NvimTreeFileConf  #\zs.*\.\(conf\|config\)$#
            hi NvimTreeFileImg  ctermfg=211    ctermbg=NONE guifg=#f48fb1 guibg=NONE
            hi NvimTreeFileMd   ctermfg=blue   ctermbg=NONE guifg=#3366FF guibg=NONE
            hi NvimTreeFileYml  ctermfg=yellow ctermbg=NONE guifg=yellow  guibg=NONE
            hi NvimTreeFileJson ctermfg=yellow ctermbg=NONE guifg=yellow  guibg=NONE
            hi NvimTreeFileHtml ctermfg=yellow ctermbg=NONE guifg=yellow  guibg=NONE
            hi NvimTreeFileCss  ctermfg=cyan   ctermbg=NONE guifg=cyan    guibg=NONE
            hi NvimTreeFileJs   ctermfg=214    ctermbg=NONE guifg=#ffa500 guibg=NONE
            hi NvimTreeFileTs   ctermfg=176    ctermbg=NONE guifg=#c586c0 guibg=NONE
            hi NvimTreeFileConf ctermfg=yellow ctermbg=NONE guifg=yellow  guibg=NONE
          ]])
        end,
      })
    end,
  },
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
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-f>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
      })
    end,
  },
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
