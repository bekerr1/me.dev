-- Syntax highlighting and structural text objects. This is the "code
-- intelligence" half of the config -- it understands the shape of a file
-- without needing a language server running.
return {
  "nvim-treesitter/nvim-treesitter",
  -- Pinned to master. The default branch is the `main` rewrite, which has a
  -- different API and has dropped `indent` and `incremental_selection`.
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "bash", "c", "cpp", "css", "diff", "dockerfile", "go", "gomod",
      "html", "javascript", "json", "jsonc", "lua", "luadoc", "make",
      "markdown", "markdown_inline", "python", "query", "regex", "rust",
      "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
    },
    auto_install = true,          -- grab a parser on first sight of a new filetype
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        -- Grow the selection by syntax node: expression, then statement,
        -- then block. Faster than counting motions.
        init_selection = "<CR>",
        node_incremental = "<CR>",
        node_decremental = "<BS>",
        scope_incremental = false,
      },
    },
  },
}
