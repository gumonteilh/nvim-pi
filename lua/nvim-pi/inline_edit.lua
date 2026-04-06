local M = {}

local settings = {
  command = { "pi" },
  model = nil,
  thinking = "off",
}

local state = {
  request = nil,
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-pi" })
end

local function is_valid_buf(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

local function build_prompt(prompt, path, filetype, line, column, contents)
  return table.concat({
    "You are performing a Neovim inline edit.",
    "Edit only this file: " .. path,
    "The current buffer contents below are the source of truth for this request.",
    "Use the cursor position to infer the smallest relevant change.",
    "Apply the change directly to the file.",
    "Do not ask follow-up questions.",
    "Do not modify any other file.",
    "",
    "User request:",
    prompt,
    "",
    "Cursor:",
    "line=" .. line .. ", column=" .. column,
    "",
    "Filetype:",
    filetype,
    "",
    "<current-file>",
    contents,
    "</current-file>",
  }, "\n")
end

local function clear_request(request)
  if state.request == request then
    state.request = nil
  end
end

local function finish(request, callback)
  if request.finished then
    return
  end

  request.finished = true
  clear_request(request)

  if request.process ~= nil and not request.process:is_closing() then
    pcall(request.process.write, request.process, nil)
  end

  vim.schedule(callback)
end

local function finish_success(request)
  finish(request, function()
    if not is_valid_buf(request.buf) then
      return
    end

    if vim.bo[request.buf].modified or vim.api.nvim_buf_get_changedtick(request.buf) ~= request.changedtick then
      notify("Pi inline edit finished, but the buffer changed before it could be reloaded", vim.log.levels.WARN)
      return
    end

    vim.cmd("checktime " .. request.buf)
    notify("Pi inline edit applied")
  end)
end

local function finish_error(request, message)
  finish(request, function()
    notify(message, vim.log.levels.ERROR)
  end)
end

local function parse_line(request, line)
  if line == "" then
    return
  end

  local ok, event = pcall(vim.json.decode, line)

  if not ok or type(event) ~= "table" then
    return
  end

  if event.type == "response" and event.success == false then
    local message = event.error or ("Pi inline edit failed during " .. (event.command or "rpc"))
    finish_error(request, message)
    return
  end

  if event.type == "agent_end" then
    finish_success(request)
  end
end

local function parse_output(request, data, flush)
  if data ~= nil then
    request.stdout_buffer = request.stdout_buffer .. data
  end

  while true do
    local index = request.stdout_buffer:find("\n", 1, true)

    if index == nil then
      break
    end

    local line = request.stdout_buffer:sub(1, index - 1)
    request.stdout_buffer = request.stdout_buffer:sub(index + 1)

    if vim.endswith(line, "\r") then
      line = line:sub(1, -2)
    end

    parse_line(request, line)
  end

  if flush and request.stdout_buffer ~= "" then
    parse_line(request, request.stdout_buffer)
    request.stdout_buffer = ""
  end
end

local function command()
  local cmd = vim.deepcopy(settings.command)

  vim.list_extend(cmd, { "--mode", "rpc", "--no-session" })

  if settings.model ~= nil and settings.model ~= "" then
    vim.list_extend(cmd, { "--model", settings.model })
  end

  return cmd
end

local function can_run(buf)
  if state.request ~= nil then
    notify("Pi inline edit is already running", vim.log.levels.WARN)
    return false
  end

  if vim.bo[buf].buftype ~= "" then
    notify("Pi inline edit only works in file buffers", vim.log.levels.WARN)
    return false
  end

  if vim.bo[buf].modified then
    notify("Save the buffer before using Pi inline edit", vim.log.levels.WARN)
    return false
  end

  if vim.api.nvim_buf_get_name(buf) == "" then
    notify("Pi inline edit only works on saved files", vim.log.levels.WARN)
    return false
  end

  return true
end

local function start(prompt)
  local buf = vim.api.nvim_get_current_buf()

  if not can_run(buf) then
    return
  end

  local path = vim.api.nvim_buf_get_name(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local request = {
    buf = buf,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    finished = false,
    process = nil,
    stderr = "",
    stdout_buffer = "",
  }
  local message = build_prompt(prompt, path, vim.bo[buf].filetype, cursor[1], cursor[2] + 1, contents)

  local ok, process = pcall(vim.system, command(), {
    cwd = vim.fn.getcwd(),
    stdin = true,
    text = true,
    stdout = function(err, data)
      if err ~= nil then
        request.stderr = request.stderr .. err
      end

      parse_output(request, data, false)
    end,
    stderr = function(err, data)
      if err ~= nil then
        request.stderr = request.stderr .. err
      end

      if data ~= nil then
        request.stderr = request.stderr .. data
      end
    end,
  }, function(result)
    parse_output(request, nil, true)

    if request.finished then
      return
    end

    if result.code == 0 then
      finish_error(request, "Pi inline edit finished without applying a change")
      return
    end

    local stderr = vim.trim(request.stderr)

    if stderr ~= "" then
      finish_error(request, stderr)
      return
    end

    finish_error(request, "Pi inline edit failed")
  end)

  if not ok then
    notify(process, vim.log.levels.ERROR)
    return
  end

  request.process = process
  state.request = request

  if settings.thinking ~= nil and settings.thinking ~= "" then
    process:write(vim.json.encode({ type = "set_thinking_level", level = settings.thinking }) .. "\n")
  end

  process:write(vim.json.encode({ type = "prompt", message = message }) .. "\n")
  notify("Pi inline edit running")
end

function M.setup(opts)
  settings = vim.tbl_deep_extend("force", settings, opts or {})
end

function M.inline_edit()
  if not can_run(vim.api.nvim_get_current_buf()) then
    return
  end

  vim.ui.input({ prompt = "Pi inline edit: " }, function(input)
    if input == nil or input == "" then
      return
    end

    start(input)
  end)
end

return M
