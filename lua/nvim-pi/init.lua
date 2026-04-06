local M = {}

local terminal = require("nvim-pi.terminal")
local inline_edit = require("nvim-pi.inline_edit")
local actions = require("nvim-pi.actions")

local defaults = {
  command = { "pi" },
  width = 80,
  auto_reload = true,
  inline_edit = {
    command = { "pi" },
    model = nil,
    thinking = "off",
  },
}

local settings = vim.deepcopy(defaults)
local state = {
  initialized = false,
  reload_group = nil,
}

local function configure_auto_reload()
  if state.reload_group ~= nil then
    pcall(vim.api.nvim_del_augroup_by_id, state.reload_group)
    state.reload_group = nil
  end

  if not settings.auto_reload then
    return
  end

  state.reload_group = vim.api.nvim_create_augroup("nvim_pi_reload", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
    group = state.reload_group,
    callback = function()
      if vim.fn.mode() == "c" then
        return
      end

      local buf = vim.api.nvim_get_current_buf()

      if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then
        return
      end

      vim.cmd("checktime")
    end,
  })
end

function M.open()
  terminal.open()
end

function M.close()
  terminal.close()
end

function M.toggle()
  terminal.toggle()
end

function M.inline_edit()
  inline_edit.inline_edit()
end

function M.ask()
  actions.ask()
end

function M.explain()
  actions.explain()
end

function M.setup(opts)
  settings = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  terminal.setup({ command = settings.command, width = settings.width })
  inline_edit.setup(settings.inline_edit)
  configure_auto_reload()
end

function M.init()
  if state.initialized then
    return
  end

  state.initialized = true

  vim.api.nvim_create_user_command("Pi", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("PiOpen", function()
    M.open()
  end, {})

  vim.api.nvim_create_user_command("PiClose", function()
    M.close()
  end, {})

  vim.api.nvim_create_user_command("PiToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("PiInlineEdit", function()
    M.inline_edit()
  end, {})

  vim.api.nvim_create_user_command("PiAsk", function()
    M.ask()
  end, {})

  vim.api.nvim_create_user_command("PiExplain", function()
    M.explain()
  end, {})

  M.setup()
end

return M
