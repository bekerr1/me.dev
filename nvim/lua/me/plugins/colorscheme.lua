-- kanagawa-dragon: muted, warm-dark, low contrast. Not a stark white theme,
-- not a neon one. tmux's status bar uses the same palette.
return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    compile = true,          -- cache the highlight groups; noticeably faster
    dimInactive = true,      -- unfocused splits recede
    terminalColors = true,
    theme = "dragon",
    background = { dark = "dragon", light = "lotus" },
    overrides = function(colors)
      local t = colors.theme
      return {
        -- Float and border colours default to the normal background, which
        -- makes telescope and diagnostics windows hard to pick out.
        NormalFloat = { bg = t.ui.bg_m3 },
        FloatBorder = { bg = t.ui.bg_m3, fg = t.ui.bg_p2 },
        FloatTitle  = { bg = t.ui.bg_m3, fg = t.ui.special, bold = true },

        TelescopeNormal       = { bg = t.ui.bg_m3, fg = t.ui.fg_dim },
        TelescopeBorder       = { bg = t.ui.bg_m3, fg = t.ui.bg_m3 },
        TelescopePromptNormal = { bg = t.ui.bg_p1 },
        TelescopePromptBorder = { bg = t.ui.bg_p1, fg = t.ui.bg_p1 },
        TelescopeResultsTitle = { bg = t.ui.bg_m3, fg = t.ui.bg_m3 },
        TelescopePreviewTitle = { bg = t.ui.bg_m3, fg = t.ui.bg_m3 },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    vim.cmd.colorscheme("kanagawa-dragon")
  end,
}
