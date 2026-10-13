if vim.g.loaded_aigent then
  return
end
vim.g.loaded_aigent = 1

local aigent = require("aigent")
local config = require("aigent.config")

-- User commands
vim.api.nvim_create_user_command("AIgent", function(opts)
  if opts.args ~= "" then
    aigent.run(opts, opts.args)
  else
    aigent.pick_and_run(opts)
  end
end, {
  nargs = "?",
  range = true,
  complete = "file",
  desc = "Pick prompt and run AIgent (or run with specified prompt file)",
})

vim.api.nvim_create_user_command("AIgentPrompt", function(opts)
  aigent.pick_and_run(opts)
end, {
  range = true,
  desc = "Pick system prompt via Telescope with preview and run",
})

vim.api.nvim_create_user_command("AIgentProvider", function()
  aigent.select_provider()
end, {
  desc = "Select AIgent provider via Telescope dropdown",
})

vim.api.nvim_create_user_command("AIgentToggleProvider", function()
  aigent.toggle_provider()
end, {
  desc = "Toggle default AIgent provider between Ollama and AGY",
})

-- Default Keymaps (can be disabled via setup({ keymaps = false }))
if config.options.keymaps then
  -- Open prompt picker (with live preview and context-aware preselection) and run on <CR>
  vim.keymap.set({ "n", "v" }, "<leader>ag", ":AIgent<CR>", {
    noremap = true,
    silent = true,
    desc = "Open AIgent prompt picker and run on <CR>",
  })

  -- Select provider via Telescope dropdown
  vim.keymap.set("n", "<leader>ap", ":AIgentProvider<CR>", {
    noremap = true,
    silent = true,
    desc = "Select AIgent provider (Ollama / AGY)",
  })
end
