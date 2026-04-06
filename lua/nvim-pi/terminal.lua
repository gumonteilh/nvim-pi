local M = {}

local settings = {
  command = { "pi" },
  width = 80,
}

local state = {
  buf = nil,
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-pi" })
end

local function is_valid_buf(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

local function find_win()
  if not is_valid_buf(state.buf) then
    return nil
  end

  local win = vim.fn.bufwinid(state.buf)

  if win == -1 or not vim.api.nvim_win_is_valid(win) then
    return nil
  end

  return win
end

local function channel()
  if not is_valid_buf(state.buf) then
    return nil
  end

  local value = vim.api.nvim_get_option_value("channel", { buf = state.buf })

  if value == 0 then
    return nil
  end

  return value
end

local function is_running()
  local value = channel()

  if value == nil then
    return false
  end

  return vim.api.nvim_get_chan_info(value).exitcode == -1
end

local function open_window()
  vim.cmd("botright vertical " .. settings.width .. "split")
  vim.cmd("vertical resize " .. settings.width)
end

local function open_terminal_window()
  vim.cmd("botright vertical " .. settings.width .. "new")
  vim.cmd("vertical resize " .. settings.width)
end

local function enter_terminal()
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  vim.cmd("startinsert")
end

local function focus_terminal()
  local win = find_win()

  if win == nil then
    return false
  end

  vim.api.nvim_set_current_win(win)
  enter_terminal()

  return true
end

local function show_terminal()
  if focus_terminal() then
    return
  end

  open_window()
  vim.api.nvim_win_set_buf(0, state.buf)
  enter_terminal()
end

local function start_terminal()
  open_terminal_window()
  state.buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.buf })

  local job = vim.fn.jobstart(settings.command, { term = true })

  if job <= 0 then
    local buf = state.buf
    state.buf = nil

    if is_valid_buf(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    notify("Failed to start pi", vim.log.levels.ERROR)
    return
  end

  enter_terminal()
end

function M.setup(opts)
  settings = vim.tbl_deep_extend("force", settings, opts or {})
end

function M.is_running()
  return is_running()
end

function M.open()
  if focus_terminal() then
    return
  end

  if is_running() then
    show_terminal()
    return
  end

  start_terminal()
end

function M.close()
  local win = find_win()

  if win == nil then
    return
  end

  vim.api.nvim_win_close(win, true)
end

function M.toggle()
  local win = find_win()

  if win ~= nil then
    vim.api.nvim_win_close(win, true)
    return
  end

  M.open()
end

function M.send(text)
  if not is_running() then
    notify("Pi is not running", vim.log.levels.WARN)
    return false
  end

  vim.fn.chansend(channel(), text)
  return true
end

return M
