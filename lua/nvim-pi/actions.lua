local M = {}

local terminal = require("nvim-pi.terminal")

local startup_delay = 1000

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-pi" })
end

local function can_query(buf, action)
  if vim.bo[buf].buftype ~= "" then
    notify("Pi " .. action .. " only works in file buffers", vim.log.levels.WARN)
    return false
  end

  if vim.api.nvim_buf_get_name(buf) == "" then
    notify("Pi " .. action .. " only works on saved files", vim.log.levels.WARN)
    return false
  end

  return true
end

local function send(message)
  if terminal.is_running() then
    terminal.open()
    vim.schedule(function()
      terminal.send(message .. "\r")
    end)
    return
  end

  terminal.open()
  vim.defer_fn(function()
    terminal.send(message .. "\r")
  end, startup_delay)
end

local function build_ask_message(path, line, question)
  return table.concat({
    "@" .. path,
    "line " .. line,
    "",
    question,
  }, "\n")
end

local function severity_name(severity)
  if severity == vim.diagnostic.severity.ERROR then
    return "ERROR"
  end

  if severity == vim.diagnostic.severity.WARN then
    return "WARN"
  end

  if severity == vim.diagnostic.severity.INFO then
    return "INFO"
  end

  if severity == vim.diagnostic.severity.HINT then
    return "HINT"
  end

  return "UNKNOWN"
end

local function diagnostic_line(diagnostic)
  return (diagnostic.lnum or 0) + 1
end

local function diagnostic_column(diagnostic)
  return (diagnostic.col or 0) + 1
end

local function build_explain_message(path, diagnostics)
  local lines = {
    "@" .. path,
    "",
    "Explain these diagnostics:",
  }

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(lines,
      "- line " ..
      diagnostic_line(diagnostic) ..
      ", column " ..
      diagnostic_column(diagnostic) ..
      " [" .. severity_name(diagnostic.severity) .. "] " .. diagnostic.message:gsub("\n", " "))
  end

  return table.concat(lines, "\n")
end

function M.ask()
  local buf = vim.api.nvim_get_current_buf()

  if not can_query(buf, "ask") then
    return
  end

  vim.ui.input({ prompt = "Pi ask: " }, function(input)
    if input == nil or input == "" then
      return
    end

    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local message = build_ask_message(path, line, input)

    send(message)
  end)
end

function M.explain()
  local buf = vim.api.nvim_get_current_buf()

  if not can_query(buf, "explain") then
    return
  end

  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local diagnostics = vim.diagnostic.get(buf, { lnum = line - 1 })

  if #diagnostics == 0 then
    notify("No diagnostics on the current line", vim.log.levels.WARN)
    return
  end

  send(build_explain_message(path, diagnostics))
end

return M
