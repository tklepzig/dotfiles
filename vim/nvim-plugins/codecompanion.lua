require("tkdf.module-available")
if not IsModuleAvailable("mcphub") then return end

require("plenary")
require("nvim-treesitter")
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
