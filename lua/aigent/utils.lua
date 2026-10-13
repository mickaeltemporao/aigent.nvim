local config = require("aigent.config")

local M = {}

--- Determine active provider for given buffer
---@param bufnr integer
---@return string provider_name
function M.get_active_provider(bufnr)
  if config.user_overrode_provider then
    return config.options.provider or "ollama"
  end
  if config.options.auto_mail_agy and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "mail" then
    return "agy"
  end
  return config.options.provider or "ollama"
end

--- Calculate insertion line with smart mail header protection
---@param bufnr integer
---@param cursor_line integer
---@param is_visual boolean
---@param end_line integer|nil
---@return integer target_line
function M.get_target_line(bufnr, cursor_line, is_visual, end_line)
  if is_visual and end_line then
    return end_line
  end

  if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "mail" then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local scan_lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(line_count, 60), false)
    for i, line in ipairs(scan_lines) do
      if line == "" then
        -- Blank line separating mail headers from body
        if cursor_line <= i then
          return i -- Insert directly below the empty line
        end
        break
      end
    end
  end

  return cursor_line
end

--- Clean LLM response: strip carriage returns, outer whitespace, and enclosing markdown code fences
---@param result_text string
---@return string[]
function M.clean_response_lines(result_text)
  local cleaned = result_text:gsub("\r\n", "\n"):gsub("^\n+", ""):gsub("\n+$", "")

  -- Strip enclosing markdown code block if present
  if cleaned:match("^```[a-zA-Z]*\n") and cleaned:match("\n```$") then
    cleaned = cleaned:gsub("^```[a-zA-Z]*\n", ""):gsub("\n```$", "")
  end

  return vim.split(cleaned, "\n", { plain = true })
end

--- Load prompt file content and return trimmed text
---@param path string|nil
---@return string|nil content, string|nil resolved_path
function M.load_prompt_content(path)
  if not path or path == "" then
    return nil, nil
  end

  local expanded = vim.fn.expand(path)
  local file = io.open(expanded, "r")
  if not file then
    return nil, nil
  end

  local content = file:read("*a")
  file:close()
  content = content:gsub("^%s*(.-)%s*$", "%1")
  return content, expanded
end

--- Get sorted list of prompt files for the current buffer context
--- Searches user prompts directory first, then plugin bundled prompts
---@param target_buf integer
---@return table files
function M.get_prompt_files(target_buf)
  local seen = {}
  local files = {}

  local function add_files_from(dir)
    local expanded = vim.fn.expand(dir)
    if vim.fn.isdirectory(expanded) == 1 then
      local matches = vim.fn.glob(expanded .. "/*.md", false, true)
      for _, f in ipairs(matches) do
        local basename = vim.fn.fnamemodify(f, ":t")
        if not seen[basename] then
          seen[basename] = true
          table.insert(files, f)
        end
      end
    end
  end

  -- User directory has precedence
  add_files_from(config.options.prompts_dir)
  -- Bundled prompts as fallback
  add_files_from(config.get_bundled_prompts_dir())

  local is_mail = vim.api.nvim_buf_is_valid(target_buf) and vim.bo[target_buf].filetype == "mail"
  local default_name = is_mail and "reply.md" or "default.md"
  local last_name = config.last_prompt_path and vim.fn.fnamemodify(config.last_prompt_path, ":t") or default_name

  local email_prompts = {
    ["reply.md"] = true,
    ["decline.md"] = true,
    ["reschedule.md"] = true,
    ["ack.md"] = true,
  }

  table.sort(files, function(a, b)
    local name_a = vim.fn.fnamemodify(a, ":t")
    local name_b = vim.fn.fnamemodify(b, ":t")

    -- 1. Pinned: Last chosen / context default is always #1
    if name_a == last_name then return true end
    if name_b == last_name then return false end

    -- 2. Context prioritization
    if is_mail then
      local a_mail = email_prompts[name_a] or false
      local b_mail = email_prompts[name_b] or false
      if a_mail ~= b_mail then return a_mail end
    else
      local a_mail = email_prompts[name_a] or false
      local b_mail = email_prompts[name_b] or false
      if a_mail ~= b_mail then return not a_mail end
    end

    -- 3. Alphabetical
    return name_a < name_b
  end)

  return files
end

return M
