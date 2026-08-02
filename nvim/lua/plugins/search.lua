local exclude = {
  ".git",
  "node_modules",
  ".next",
  ".nuxt",
  ".svelte-kit",
  "dist",
  "build",
  "coverage",
  "__pycache__",
  ".pytest_cache",
  ".mypy_cache",
  ".ruff_cache",
  ".venv",
  "venv",
  ".DS_Store",
}

local rg_extra_args = vim.tbl_map(function(pattern)
  return "--glob=!" .. pattern
end, exclude)

table.insert(rg_extra_args, 1, "--hidden")

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      for _, source in ipairs({ "files", "grep", "grep_word" }) do
        opts.picker.sources[source] = opts.picker.sources[source] or {}
        opts.picker.sources[source].hidden = true
        opts.picker.sources[source].exclude =
          vim.list_extend(opts.picker.sources[source].exclude or {}, exclude)
      end
    end,
  },
  {
    "MagicDuck/grug-far.nvim",
    opts = function(_, opts)
      opts.engines = opts.engines or {}
      opts.engines.ripgrep = opts.engines.ripgrep or {}

      local existing = opts.engines.ripgrep.extraArgs or ""
      opts.engines.ripgrep.extraArgs = vim.trim(existing .. " " .. table.concat(rg_extra_args, " "))
    end,
  },
}
