-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local hunk_win

vim.keymap.set("n", "<leader>gH", function()
  if vim.fn.executable("hunk") == 0 then
    vim.notify("hunk command not found", vim.log.levels.ERROR)
    return
  end

  if hunk_win and vim.api.nvim_win_is_valid(hunk_win) then
    vim.api.nvim_set_current_win(hunk_win)
    return
  end

  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.uv.cwd()
  end

  local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or not root then
    vim.notify("not inside a git repository", vim.log.levels.ERROR)
    return
  end

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local buf = vim.api.nvim_create_buf(false, true)

  hunk_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
    title = " hunk diff ",
    title_pos = "center",
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.fn.termopen({ "hunk", "diff" }, { cwd = root })
  vim.cmd("startinsert")
end, { desc = "Hunk Diff" })
