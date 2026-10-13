local config = require("aigent.config")

local M = {}

--- Run query using AGY CLI
---@param prompt_text string
---@param user_content string
---@param on_success function callback with result text
---@param on_error function callback with error message
function M.run_agy(prompt_text, user_content, on_success, on_error)
  local agy_cfg = config.options.agy or {}
  local model_name = agy_cfg.model or "gemini-3.8-flash-low"
  local agy_cmd = agy_cfg.cmd or "agy"

  local combined_prompt = string.format("System Instructions:\n%s\n\nInput Context:\n%s", prompt_text, user_content)
  local cmd = {
    agy_cmd,
    "--model",
    model_name,
    "--disable-slash-commands",
    "-p",
    combined_prompt,
  }

  vim.system(cmd, { text = true }, function(obj)
    if obj.code ~= 0 then
      local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or (obj.stdout or ("Exit code " .. tostring(obj.code)))
      on_error("AGY failed: " .. err_msg)
      return
    end

    local out = obj.stdout or ""
    if vim.trim(out) == "" then
      on_error("AGY generated empty response.")
      return
    end

    on_success(out, "AGY (" .. model_name .. ")")
  end)
end

--- Run query using Ollama / OpenAI-compatible HTTP endpoint
---@param prompt_text string
---@param user_content string
---@param on_success function callback with result text
---@param on_error function callback with error message
function M.run_ollama(prompt_text, user_content, on_success, on_error)
  local ollama_cfg = config.options.ollama or {}
  local model_name = ollama_cfg.model or "llama3.2"
  local endpoint_url = ollama_cfg.endpoint or "http://localhost:11434/v1/chat/completions"

  -- Ensure /chat/completions path is appended if missing
  if not endpoint_url:match("chat/completions$") then
    if not endpoint_url:match("/$") then
      endpoint_url = endpoint_url .. "/"
    end
    endpoint_url = endpoint_url .. "chat/completions"
  end

  local payload_data = {
    model = model_name,
    messages = {
      { role = "system", content = prompt_text },
      { role = "user", content = user_content },
    },
    temperature = config.options.temperature or 0.7,
  }

  local payload_json = vim.json.encode(payload_data)

  local cmd = {
    "curl",
    "-sS",
    "-X",
    "POST",
    endpoint_url,
    "-H",
    "Content-Type: application/json",
  }

  if ollama_cfg.api_key and ollama_cfg.api_key ~= "" then
    table.insert(cmd, "-H")
    table.insert(cmd, "Authorization: Bearer " .. ollama_cfg.api_key)
  end

  table.insert(cmd, "-d")
  table.insert(cmd, payload_json)

  vim.system(cmd, { text = true }, function(obj)
    if obj.code ~= 0 then
      local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or ("Exit code " .. tostring(obj.code))
      on_error("Request failed: " .. err_msg)
      return
    end

    local success, response = pcall(vim.json.decode, obj.stdout)
    if not success or not response then
      local snippet = (obj.stdout and #obj.stdout > 0) and string.sub(obj.stdout, 1, 200) or "Empty response"
      on_error("Failed to parse API JSON response:\n" .. snippet)
      return
    end

    if response.error then
      local err_detail = type(response.error) == "table" and (response.error.message or vim.inspect(response.error)) or tostring(response.error)
      on_error("API Error: " .. err_detail)
      return
    end

    local choices = response.choices
    if not choices or #choices == 0 or not choices[1].message then
      on_error("No text generated in response.")
      return
    end

    local result_text = choices[1].message.content or ""
    on_success(result_text, "Ollama (" .. model_name .. ")")
  end)
end

return M
