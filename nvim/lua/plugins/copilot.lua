return {
  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_maps = true
    end,
    config = function()
      vim.keymap.set("i", "<C-t>", 'copilot#AcceptWord("")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot word",
      })
      vim.keymap.set("i", "<C-y>", 'copilot#Accept("")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      })
      vim.keymap.set("i", "<C-u>", "<Cmd>call copilot#Dismiss()<CR>", { desc = "Dismiss Copilot suggestion" })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = { keymap = { ["<C-y>"] = false } },
  },
}
