-- Cursor / VS Code, via the vscode-neovim extension.
--
-- Only motions and command dispatch make sense here; the host owns the UI.
-- The point is that muscle memory carries over -- J/K travel, ss saves, d does
-- not clobber the yank register.

local vscode = require("vscode")
local map = vim.keymap.set

local function action(name)
  return function() vscode.action(name) end
end

map({ "n", "v" }, "J", "15jzz")
map({ "n", "v" }, "K", "15kzz")
map("n", "n", "nzz")
map("n", "N", "Nzz")

map("n", "d", '"_d')
map("n", "dd", '"_dd')
map("v", "d", '"_d')
map("v", "p", '"0p')

map("n", "ss", "<cmd>w<cr>")
map("n", "QQ", "<cmd>q<cr>")

map("n", "<C-n>", action("workbench.view.explorer"))
map("n", "H", action("workbench.action.previousEditor"))
map("n", "L", action("workbench.action.nextEditor"))
map("n", "<C-f>", action("workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup"))
map("n", "<C-e>", action("workbench.action.focusActiveEditorGroup"))
map("n", "<C-t>", action("workbench.action.terminal.toggleTerminal"))
