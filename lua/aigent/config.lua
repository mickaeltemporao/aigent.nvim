local M = {}

--- Get directory where plugin's bundled prompts are located
---@return string
function M.get_bundled_prompts_dir()
  local info = debug.getinfo(1, "S").source
  if vim.startswith(info, "@") then
    info = info:sub(2)
  end
  -- Path resolution: lua/aigent/config.lua -> ../../prompts
  local plugin_root = vim.fn.fnamemodify(info, ":p:h:h:h")
  return plugin_root .. "/prompts"
end

M.defaults = {
  -- Active provider: "ollama" or "agy"
  provider = "ollama",

  -- AGY provider settings (fast cloud models via agy CLI)
  agy = {
    cmd = "agy",
    model = "gemini-3.8-flash-low",
  },

  -- Ollama / OpenAI-compatible endpoint settings
  ollama = {
    endpoint = "https://engineers-has-rows-turned.trycloudflare.com/v1/chat/completions",
    model = "muse-glimmer:30b-mlx",
    api_key = os.getenv("OPENAI_API_KEY") or "ollama",
  },

  -- Custom prompts directory (defaults to ~/.config/nvim/prompts)
  prompts_dir = vim.fn.stdpath("config") .. "/prompts",

  -- Insertion behavior: "append" (below cursor/headers) or "replace"
  insert_mode = "append",
  temperature = 0.7,

  -- Automatically use AGY when filetype is 'mail' (e.g., NeoMutt)
  auto_mail_agy = true,

  -- Automatically set up default keymaps (<leader>ag and <leader>ap)
  keymaps = true,
}

M.options = vim.deepcopy(M.defaults)
M.last_prompt_path = nil
M.user_overrode_provider = false

--- Setup function to merge user configuration
---@param user_opts table|nil
function M.setup(user_opts)
  if user_opts then
    M.options = vim.tbl_deep_extend("force", M.defaults, user_opts)
  else
    M.options = vim.deepcopy(M.defaults)
  end

  -- Try user prompt first, fallback to bundled prompt
  local user_default = vim.fn.expand(M.options.prompts_dir) .. "/default.md"
  local bundled_default = M.get_bundled_prompts_dir() .. "/default.md"

  if vim.fn.filereadable(user_default) == 1 then
    M.last_prompt_path = user_default
  elseif vim.fn.filereadable(bundled_default) == 1 then
    M.last_prompt_path = bundled_default
  end
end

return M
