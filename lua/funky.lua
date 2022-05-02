local M = {}

local default_config = {
  -- debug = true,
  selected_prefix = "",
  lua = {
    {
      -- regex = "^local function(.*)%(",
      sortable = true,
      selectable = true,
      -- fixed_width = 20,
      treesitter_kind = "function",
    },
  },
  diff = {
    {
      regex = "^--- a(.*)",
      sortable = true,
      selectable = true,
    }
  },
  c = {
    {
      sortable = true,
      selectable = true,
      treesitter_kind = "function",
    }
  },
}
local config = {}
setmetatable(config, {__index = default_config})
M.config = config

function M.setup(opts)
  local new_config = vim.tbl_deep_extend('force', default_config, opts)
  setmetatable(config, {__index = new_config})

  -- for k, v in pairs(opts) do
  --   if type(v) == "table" then
  --     config[k] = config[k] or v
  --     config[k] = vim.tbl_deep_extend('force', config[k], v)
  --   else
  --     config[k] = v
  --   end
  -- end
end

function M.check_config()
  print(vim.inspect(config))
end

function M.debug()
  local debug_on = M.config.debug or false
  if debug_on then
    local debug_fn = function (str, table)
      if str then
        print(str)
      end
      if table then
        print(vim.inspect(table))
      end
    end
    return debug_fn
  else
    local empty_fn = function ()
    end
    return empty_fn
  end
end

return M
