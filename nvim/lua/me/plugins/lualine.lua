-- The bar along the bottom. Deliberately narrow in what it reports: mode,
-- branch, file, diagnostics, position. No LSP progress, no plugin counters.
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "kanagawa",
      icons_enabled = true,
      -- Plain separators: no powerline glyphs, so the bar renders correctly
      -- over ssh on a machine without a patched font.
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
      disabled_filetypes = { statusline = { "NvimTree" } },
    },
    sections = {
      lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
      lualine_b = {
        {
          "branch",
          fmt = function(s)
            -- Long feature-branch names would otherwise push the filename off.
            return #s > 20 and s:sub(1, 17) .. "…" or s
          end,
        },
        "diff",
      },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = " ●", readonly = " ", newfile = " " } },
      },
      lualine_x = {
        { "diagnostics", sources = { "nvim_diagnostic" } },
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
    },
    extensions = { "nvim-tree", "lazy", "quickfix", "man" },
  },
}
