-- Two very different environments load this file:
--
--   * Cursor / VS Code, through the vscode-neovim extension. There is no UI to
--     configure -- only motions and a handful of command bindings apply.
--   * A real terminal nvim. Full config.
--
-- Options and autocmds are shared; plugins are terminal-only, since loading a
-- statusline or a file tree inside Cursor would be meaningless at best.

require("me.config.options")
require("me.config.autocmds")

if vim.g.vscode then
  require("me.config.vscode")
  return
end

require("me.config.keymaps")
require("me.config.lazy")
