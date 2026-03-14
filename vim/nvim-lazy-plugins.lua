return {
  { "nvim-lua/plenary.nvim" },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("CopilotChat").setup({
        build = function()
          vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
        end,
        event = "VeryLazy",
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
    -- build step must be done manually: npm i -g mcp-hub@latest && asdf reshim nodejs
    config = function()
      require("mcphub").setup()
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
