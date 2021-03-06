local debug = require('funky').debug()
local M = {}

local function merge_index_tables(tbl1, tbl2)
  if tbl1 == nil or tbl2 == nil then
    return tbl1 or tbl2 or {}
  end

  local base_tbl
  local addon_tbl
  if #tbl1 >= #tbl2 then
    base_tbl = tbl1
    addon_tbl = tbl2
  else
    base_tbl = tbl2
    addon_tbl = tbl1
  end

  for _, value in pairs(addon_tbl) do
    table.insert(base_tbl, value)
  end

  return base_tbl
end


local function prepare_match(entry)
  local entries = {}

  if entry.node then
    table.insert(entries, entry)
  else
    for _, item in pairs(entry) do
      vim.list_extend(entries, prepare_match(item))
    end
  end
  return entries
end

-- @table rules col_idx=kind
-- @return { col_idx, text, lnum }
M.make_results = function (rules)
  if rules == nil or next(table) == nil  then
    return {}
  end

  local ts_locals = require "nvim-treesitter.locals"
  local parsers = require "nvim-treesitter.parsers"
  local ts_utils = require "nvim-treesitter.ts_utils"
  local has_nvim_treesitter, _ = pcall(require, "nvim-treesitter")
  if not has_nvim_treesitter then
    print("has no treesitter")
    return {}
  end
  local bufnr = vim.api.nvim_get_current_buf()
  if not parsers.has_parser(parsers.get_buf_lang(bufnr)) then
    print("has no parser")
    return {}
  end

  local results = {}
  for col_idx, _ in pairs(rules) do
    results[col_idx] = {}
  end

  -- @return table kind={text, lnum}
  local function get_treesitter_all()
    local treesitter_all = {}
    local filter_duplicates_map = {}
    for _, definition in ipairs(ts_locals.get_definitions(bufnr)) do
      local entries = prepare_match(ts_locals.get_local_nodes(definition))
      for _, entry in ipairs(entries) do
        entry.kind = vim.F.if_nil(entry.kind, "")
        -- local text = ts_utils.get_node_text(entry.node, bufnr)[1]
        local text = vim.treesitter.query.get_node_text(entry.node, bufnr)
        local lnum, _, _, _ = ts_utils.get_node_range(entry.node)

        if filter_duplicates_map[text] == nil then
          filter_duplicates_map[text] = true

          treesitter_all[entry.kind] = treesitter_all[entry.kind] or {}
          table.insert(treesitter_all[entry.kind], {
            text = text,
            lnum = lnum + 1, -- treesitter begin with 0
          })
        end
      end
    end
    return treesitter_all
  end

  local function pick_treesitter_data(treesitter_all)
    for col_idx, kind_rule in pairs(rules) do
      -- kind_rule maybe: "function|type"
      for kind in string.gmatch(kind_rule, "%a+") do
        results[col_idx] = merge_index_tables(results[col_idx], treesitter_all[kind])
      end
    end
    debug("treesitter results:", results)
    return results
  end

  return pick_treesitter_data(get_treesitter_all())
end

return M
