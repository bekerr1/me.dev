-- Git signs in the gutter, plus hunk navigation and staging. Enough to review
-- and stage from the editor; anything more involved happens in the terminal.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" }, change = { text = "▎" },
      delete = { text = "▁" }, topdelete = { text = "▔" },
      changedelete = { text = "▎" }, untracked = { text = "▎" },
    },
    current_line_blame = false,   -- toggled on demand with <leader>gb
    current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
    preview_config = { border = "rounded" },
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
      end

      -- ]c / [c match the built-in diff-mode motions.
      map("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
      map("n", "[c", function() gs.nav_hunk("prev") end, "Previous hunk")

      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
      map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
      map("n", "<leader>gd", gs.diffthis, "Diff this file")
    end,
  },
}
