-- lazy.nvim bootstrap. Clones itself on first launch; nothing to pre-install.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "me.plugins" } },
  defaults = { lazy = true },
  install = { colorscheme = { "kanagawa-dragon" } },
  checker = { enabled = false },   -- no background update checks
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      -- Built-in plugins this config replaces or never uses. Trimming the
      -- runtimepath is most of the difference between a 30ms and a 90ms start.
      disabled_plugins = {
        "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor",
        "netrwPlugin", "matchit", "rplugin", "spellfile",
      },
    },
  },
})
