local o = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Indentation: tabs, four wide. Per-language overrides live in autocmds.lua.
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = false
o.smartindent = true

o.number = true
o.relativenumber = false
o.numberwidth = 3
o.ruler = false
o.cursorline = true
o.cursorlineopt = "number"   -- highlight the number, not the whole row
o.signcolumn = "yes"         -- always on, so text does not jump when a sign appears
o.scrolloff = 6
o.sidescrolloff = 8

o.wrap = false
o.linebreak = true           -- when wrap is on (markdown), break at words

o.ignorecase = true
o.smartcase = true           -- a capital in the query makes the search case-sensitive
o.incsearch = true
o.hlsearch = true

o.splitbelow = true
o.splitright = true

o.undofile = true            -- undo survives closing the file
o.undolevels = 10000
o.swapfile = false
o.updatetime = 200           -- drives CursorHold, and gitsigns' blame delay
o.timeoutlen = 400           -- how long to wait for a mapping to complete

o.clipboard = "unnamedplus"  -- yank straight to the system clipboard
o.termguicolors = true
o.completeopt = "menuone,noselect"
o.shortmess:append("I")      -- no intro screen
o.confirm = true             -- prompt instead of failing on :q with changes

o.list = true
o.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

o.laststatus = 3             -- one statusline for the whole window layout
