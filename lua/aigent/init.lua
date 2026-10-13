local config = require("aigent.config")
local utils = require("aigent.utils")
local providers = require("aigent.providers")

local M = {}

--- Setup function for aigent
---@param user_opts table|nil
function M.setup(user_opts)
  config.setup(user_opts)
end

--- Toggle default provider between "ollama" and "agy"
function M.toggle_provider()
  if config.options.provider == "agy" then
    config.options.provider = "ollama"
  else
    config.options.provider = "agy"
  end
  config.user_overrode_provider = true
  vim.notify("Aigent: Default provider switched to '" .. config.options.provider .. "'", vim.log.levels.INFO)
end

--- Open Telescope dropdown picker to select default provider
function M.select_provider()
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  local has_finders, finders = pcall(require, "telescope.finders")
  local has_conf, conf = pcall(require, "telescope.config")
  local has_actions, actions = pcall(require, "telescope.actions")
  local has_action_state, action_state = pcall(require, "telescope.actions.state")
  local has_themes, themes = pcall(require, "telescope.themes")

  local function apply_choice(choice)
    if choice then
      config.options.provider = choice
      config.user_overrode_provider = true
      vim.notify("Aigent: Default provider set to '" .. choice .. "'", vim.log.levels.INFO)
    end
  end

  if not has_telescope or not has_finders or not has_conf or not has_actions or not has_action_state or not has_themes then
    vim.ui.select({ "ollama", "agy" }, {
      prompt = "Select Aigent Provider (Current: " .. config.options.provider .. "):",
    }, apply_choice)
    return
  end

  local current_p = config.options.provider
  local ollama_model = (config.options.ollama and config.options.ollama.model) or "local"
  local agy_model = (config.options.agy and config.options.agy.model) or "gemini-3.8-flash-low"

  local items = {
    {
      id = "ollama",
      label = (current_p == "ollama" and "* " or "  ") .. "ollama  [" .. ollama_model .. "]",
    },
    {
      id = "agy",
      label = (current_p == "agy" and "* " or "  ") .. "agy     [" .. agy_model .. "]",
    },
  }

  local opts = themes.get_dropdown({
    prompt_title = "Select LLM Provider (Current: " .. current_p .. ")",
  })

  pickers.new(opts, {
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        return {
          value = entry.id,
          display = entry.label,
          ordinal = entry.id .. " " .. entry.label,
        }
      end,
    }),
    sorter = conf.values.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          apply_choice(selection.value)
        end
      end)
      return true
    end,
  }):find()
end

--- Open Telescope prompt picker with live preview and run on selection
---@param opts table|nil
function M.pick_and_run(opts)
  opts = opts or {}
  local target_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_opts = {
    bufnr = target_buf,
    cursor_line = cursor_line,
    range = opts.range,
    line1 = opts.line1,
    line2 = opts.line2,
  }

  local has_telescope, pickers = pcall(require, "telescope.pickers")
  local has_finders, finders = pcall(require, "telescope.finders")
  local has_conf, conf = pcall(require, "telescope.config")
  local has_actions, actions = pcall(require, "telescope.actions")
  local has_action_state, action_state = pcall(require, "telescope.actions.state")

  if not has_telescope or not has_finders or not has_conf or not has_actions or not has_action_state then
    vim.notify("Aigent Error: Telescope is required to pick prompt files.", vim.log.levels.ERROR)
    return
  end

  local files = utils.get_prompt_files(target_buf)
  if #files == 0 then
    vim.notify("Aigent: No prompt files found.", vim.log.levels.WARN)
    return
  end

  local active_provider = utils.get_active_provider(target_buf)
  local provider_display = active_provider == "agy"
    and ("agy: " .. ((config.options.agy and config.options.agy.model) or "gemini-3.8-flash-low"))
    or ("ollama: " .. ((config.options.ollama and config.options.ollama.model) or "local"))

  local picker_opts = {
    prompt_title = "Select Prompt [" .. provider_display .. "]",
  }

  pickers.new(picker_opts, {
    finder = finders.new_table({
      results = files,
      entry_maker = function(path)
        local filename = vim.fn.fnamemodify(path, ":t")
        local is_last = (config.last_prompt_path and vim.fn.fnamemodify(config.last_prompt_path, ":t") == filename)
        local display_text = is_last and (filename .. " (current)") or filename
        return {
          value = path,
          display = display_text,
          ordinal = filename,
          path = path,
        }
      end,
    }),
    sorter = conf.values.generic_sorter(picker_opts),
    previewer = conf.values.file_previewer(picker_opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then
          return
        end
        config.last_prompt_path = selection.value
        M.run(current_opts, selection.value, active_provider)
      end)
      return true
    end,
  }):find()
end

--- Execute LLM query on target buffer or visual selection
---@param opts table|nil Command options containing line range information
---@param custom_prompt_path string|nil Optional override for prompt file path
---@param provider string|nil Optional provider override ("ollama" or "agy")
function M.run(opts, custom_prompt_path, provider)
  opts = opts or {}
  local target_buf = opts.bufnr or vim.api.nvim_get_current_buf()
  local active_provider = provider or utils.get_active_provider(target_buf)
  local target_prompt_path = custom_prompt_path or config.last_prompt_path

  if not target_prompt_path or target_prompt_path == "" then
    -- Prompt user to select if none set yet, then run
    M.pick_and_run(opts)
    return
  end

  local prompt_text, prompt_file = utils.load_prompt_content(target_prompt_path)
  if not prompt_text then
    vim.notify("Aigent Error: Could not read prompt at '" .. tostring(target_prompt_path) .. "'", vim.log.levels.ERROR)
    return
  end

  -- Update last_prompt_path so subsequent runs can reuse it
  config.last_prompt_path = prompt_file

  local cursor_pos_line = opts.cursor_line or (vim.api.nvim_buf_is_valid(target_buf) and vim.api.nvim_win_get_cursor(0)[1] or 1)

  -- Determine input text & range
  local is_visual = opts.range and opts.range ~= 0
  local start_line, end_line

  if is_visual then
    start_line = opts.line1 - 1
    end_line = opts.line2
  else
    start_line = 0
    end_line = vim.api.nvim_buf_line_count(target_buf)
  end

  local lines = vim.api.nvim_buf_get_lines(target_buf, start_line, end_line, false)
  local user_content = table.concat(lines, "\n")

  if #user_content == 0 then
    vim.notify("Aigent: Buffer/selection is empty.", vim.log.levels.WARN)
    return
  end

  -- Calculate target line with smart email header protection
  local target_insertion_line = utils.get_target_line(target_buf, cursor_pos_line, is_visual, end_line)

  -- Notification
  local prompt_name = vim.fn.fnamemodify(prompt_file, ":t")
  vim.notify("Aigent [" .. prompt_name .. " via " .. active_provider .. "]: Sending request...", vim.log.levels.INFO)

  local function on_success(result_text, provider_label)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(target_buf) then
        target_buf = 0
      end

      local result_lines = utils.clean_response_lines(result_text)

      -- Replace selection/buffer or append below target line
      if config.options.insert_mode == "replace" then
        vim.api.nvim_buf_set_lines(target_buf, start_line, end_line, false, result_lines)
      else
        vim.api.nvim_buf_set_lines(target_buf, target_insertion_line, target_insertion_line, false, result_lines)
      end

      vim.notify("Aigent [" .. prompt_name .. " via " .. provider_label .. "]: Response inserted!", vim.log.levels.INFO)
    end)
  end

  local function on_error(err_msg)
    vim.schedule(function()
      vim.notify("Aigent Error: " .. err_msg, vim.log.levels.ERROR)
    end)
  end

  if active_provider == "agy" then
    providers.run_agy(prompt_text, user_content, on_success, on_error)
  else
    providers.run_ollama(prompt_text, user_content, on_success, on_error)
  end
end

return M
