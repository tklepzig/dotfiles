require("tkdf.module-available")
if not IsModuleAvailable("mcphub") then return end

require("plenary")
require("nvim-treesitter")
require("codecompanion").setup({
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true
      }
    }
  }
})
