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
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<leader>j", "J")

map("n", "d", '"_d')
map("n", "dd", '"_dd')
map("v", "d", '"_d')
map({ "n", "v" }, "<leader>d", "d")
map("v", "p", '"0p')

map("n", "ss", "<cmd>w<cr>")
map("n", "QQ", "<cmd>q<cr>")
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Window moves: the editor groups and panels stand in for nvim splits.
map("n", "<C-h>", action("workbench.action.navigateLeft"))
map("n", "<C-j>", action("workbench.action.navigateDown"))
map("n", "<C-k>", action("workbench.action.navigateUp"))
map("n", "<C-l>", action("workbench.action.navigateRight"))

map("n", "<leader>e", action("editor.action.showHover"))

-- Telescope's leader-f family, mapped onto the host's pickers.
map("n", "<leader>ff", action("workbench.action.quickOpen"))
map("n", "<leader>fg", action("workbench.action.findInFiles"))
map("n", "<leader>fb", action("workbench.action.showAllEditors"))
map("n", "<leader>fr", action("workbench.action.openRecent"))
map("n", "<leader>fc", action("actions.find"))
map("n", "<leader>fd", action("workbench.actions.view.problems"))
map("n", "<leader>fw", function()
  vscode.action("workbench.action.findInFiles", { args = { query = vim.fn.expand("<cword>") } })
end)

-- gitsigns equivalents.
map("n", "]c", action("workbench.action.editor.nextChange"))
map("n", "[c", action("workbench.action.editor.previousChange"))
map("n", "<leader>gp", action("editor.action.dirtydiff.next"))
map({ "n", "v" }, "<leader>gs", action("git.stageSelectedRanges"))
map("n", "<leader>gr", action("git.revertSelectedRanges"))
map("n", "<leader>gb", action("git.blame.toggleEditorDecoration"))
map("n", "<leader>gd", action("git.openChange"))

map("n", "<leader>tf", action("workbench.files.action.focusFilesExplorer"))

map("n", "<C-n>", action("workbench.view.explorer"))
map("n", "H", action("workbench.action.previousEditor"))
map("n", "L", action("workbench.action.nextEditor"))
map("n", "<C-f>", action("workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup"))
map("n", "<C-e>", action("workbench.action.focusActiveEditorGroup"))
map("n", "<C-t>", action("workbench.action.terminal.toggleTerminal"))
