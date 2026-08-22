local map = vim.keymap.set

-- --- movement -------------------------------------------------------------
-- The main reason to reach for nvim: fast vertical travel through a file.
-- zz recentres so the cursor stays mid-screen instead of walking to the edge.
map("n", "J", "15jzz", { desc = "Down 15 lines" })
map("n", "K", "15kzz", { desc = "Up 15 lines" })
map("v", "J", "15jzz", { desc = "Down 15 lines" })
map("v", "K", "15kzz", { desc = "Up 15 lines" })

map("n", "n", "nzz", { desc = "Next match, centred" })
map("n", "N", "Nzz", { desc = "Previous match, centred" })
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- J is remapped above, so give line-join a home.
map("n", "<leader>j", "J", { desc = "Join lines" })

-- --- registers ------------------------------------------------------------
-- Deletes go to the black hole so a yank survives an intervening delete;
-- use leader-d when the deleted text is actually wanted.
map("n", "d", '"_d')
map("n", "dd", '"_dd')
map("v", "d", '"_d')
map({ "n", "v" }, "<leader>d", "d", { desc = "Delete into the unnamed register" })
map("v", "p", '"0p', { desc = "Paste the last yank, not the last delete" })

-- --- files ----------------------------------------------------------------
map("n", "ss", "<cmd>w<cr>", { desc = "Save" })
map("n", "QQ", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- --- windows --------------------------------------------------------------
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- --- diagnostics ----------------------------------------------------------
map("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { scope = "line" })
end, { desc = "Line diagnostics" })

-- --- terminal -------------------------------------------------------------
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })
