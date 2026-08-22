-- Fuzzy finding. Ripgrep does the searching, so live_grep is fast even in
-- large repos; without rg on PATH, grep falls back to being unusably slow.
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      -- Native sorter. Skipped automatically on machines without a compiler.
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function() return vim.fn.executable("make") == 1 end,
    },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search this buffer" },
    { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
  },
  opts = function()
    local actions = require("telescope.actions")
    return {
      defaults = {
        prompt_prefix = "  ",
        selection_caret = "▌ ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = { horizontal = { prompt_position = "top", preview_width = 0.55 } },
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading", "--with-filename",
          "--line-number", "--column", "--smart-case", "--hidden",
          "--glob", "!**/.git/*",
          "--glob", "!**/node_modules/*",
        },
        mappings = {
          i = {
            ["<Esc>"] = actions.close,      -- one keypress out, no normal mode detour
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-u>"] = false,              -- free it up to clear the prompt
          },
        },
      },
      pickers = {
        find_files = { hidden = true, find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" } },
        buffers = { sort_mru = true, ignore_current_buffer = true },
      },
    }
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
