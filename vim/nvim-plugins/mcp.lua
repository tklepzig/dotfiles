require("tkdf.module-available")
if not IsModuleAvailable("mcphub") then return end

require("plenary")
-- TODO With lazy.nvim a build step can be defined
-- So this step needs to be done manually for now
-- npm i -g mcp-hub@latest && asdf reshim nodejs
require("mcphub").setup()
