-- File tree on C-n. FindFileToggle reveals the current buffer in the tree when
-- opening, rather than dumping you at the project root.
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- cmd as well as keys, so :NvimTree* works before the plugin has been opened.
  cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle", "NvimTreeFocus", "NvimTreeOpen" },
  keys = {
    { "<C-n>", "<cmd>NvimTreeFindFileToggle<cr>", desc = "Toggle file tree" },
    { "<leader>tf", "<cmd>NvimTreeFocus<cr>", desc = "Focus file tree" },
  },
  init = function()
    -- Must be set before nvim starts handling the buffer, hence init not config.
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  opts = {
    hijack_cursor = true,
    sync_root_with_cwd = true,
    view = { width = 34, signcolumn = "no" },
    renderer = {
      group_empty = true,          -- collapse a/b/c chains into one row
      indent_markers = { enable = true },
      icons = { git_placement = "right_align" },
    },
    filters = { dotfiles = false, custom = { "^.git$", "^node_modules$", "^.venv$", "^__pycache__$" } },
    actions = { open_file = { quit_on_open = false, window_picker = { enable = false } } },
    git = { enable = true, ignore = false },
    diagnostics = { enable = true, show_on_dirs = true },
  },
}
