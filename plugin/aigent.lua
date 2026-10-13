if vim.g.loaded_aigent then
  return
end
vim.g.loaded_aigent = 1

local aigent = require("aigent")
local config = require("aigent.config")

-- User commands
vim.api.nvim_create_user_command("Aigent", function(opts)
  if opts.args ~= "" then
    aigent.run(opts, opts.args)
  else
    aigent.pick_and_run(opts)
  end
end, {
  nargs = "?",
  range = true,
  complete = "file",
  desc = "Pick prompt and run Aigent (or run with specified prompt file)",
})

-- Alias for backwards compatibility
vim.api.nvim_create_user_command("LLMAgent", function(opts)
  vim.cmd.Aigent(opts.args)
end, {
  nargs = "?",
  range = true,
  complete = "file",
  desc = "Alias for :Aigent",
})

vim.api.nvim_create_user_command("AigentPrompt", function(opts)
  aigent.pick_and_run(opts)
end, {
  range = true,
  desc = "Pick system prompt via Telescope with preview and run",
})

vim.api.nvim_create_user_command("AigentProvider", function()
  aigent.select_provider()
end, {
  desc = "Select Aigent provider via Telescope dropdown",
})

vim.api.nvim_create_user_command("AigentToggleProvider", function()
  aigent.toggle_provider()
end, {
  desc = "Toggle default Aigent provider between Ollama and AGY",
})

-- Default Keymaps (can be disabled via setup({ keymaps = false }))
if config.options.keymaps then
  -- Open prompt picker (with live preview and context-aware preselection) and run on <CR>
  vim.keymap.set({ "n", "v" }, "<leader>ag", ":Aigent<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Aigent prompt picker and run on <CR>",
  })

  -- Select provider via Telescope dropdown
  vim.keymap.set("n", "<leader>ap", ":AigentProvider<CR>", {
    noremap = true,
    silent = true,
    desc = "Select Aigent provider (Ollama / AGY)",
  })
end
