local augroup = vim.api.nvim_create_augroup("me", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Per-language indentation. Values follow each language's own convention
-- rather than a single house style, so diffs stay clean in shared repos.
local indents = {
  go     = { 4, false },
  make   = { 4, false },
  python = { 4, true },
  rust   = { 4, true },
  c      = { 4, true },
  cpp    = { 4, true },
  lua    = { 2, true },
  sh     = { 2, true },
  bash   = { 2, true },
  yaml   = { 2, true },
  json   = { 2, true },
  html   = { 2, true },
  css    = { 2, true },
  javascript = { 2, true },
  typescript = { 2, true },
  typescriptreact = { 2, true },
  markdown = { 2, true },
}

for ft, spec in pairs(indents) do
  autocmd("FileType", {
    group = augroup,
    pattern = ft,
    callback = function()
      vim.bo.tabstop = spec[1]
      vim.bo.shiftwidth = spec[1]
      vim.bo.softtabstop = spec[1]
      vim.bo.expandtab = spec[2]
    end,
  })
end

-- Prose: soft wrap, and make j/k move by screen line so a wrapped paragraph
-- navigates the way it looks.
autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "rst", "tex", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.number = false
    for _, k in ipairs({ "j", "k", "0", "$", "^" }) do
      vim.keymap.set("n", k, "g" .. k, { buffer = true, silent = true })
    end
  end,
})

-- Briefly highlight yanked text -- cheap confirmation that the motion did what
-- you meant.
autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Reopen a file on the line you left it.
autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    if vim.bo[args.buf].filetype == "gitcommit" then return end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Strip trailing whitespace on save, except where it is meaningful.
autocmd("BufWritePre", {
  group = augroup,
  callback = function()
    if vim.tbl_contains({ "markdown", "diff" }, vim.bo.filetype) then return end
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[silent! %s/\s\+$//e]])
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end,
})

-- Close scratch-ish buffers with a bare q.
autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})
