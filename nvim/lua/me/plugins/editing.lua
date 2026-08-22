return {
  -- Close brackets and quotes as you type.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },   -- treesitter-aware: no pairing inside strings
  },

  -- Indent guides. indentmini is a few hundred lines and draws with extmarks,
  -- which is why it is here instead of the heavier alternatives.
  {
    "nvimdev/indentmini.nvim",
    event = "BufReadPre",
    opts = { char = "│", exclude = { "markdown", "help", "NvimTree", "lazy" } },
    config = function(_, opts)
      require("indentmini").setup(opts)
      vim.cmd.highlight("default link IndentLine Comment")
      vim.api.nvim_set_hl(0, "IndentLine", { fg = "#282727" })
      vim.api.nvim_set_hl(0, "IndentLineCurrent", { fg = "#54546d" })
    end,
  },
}
