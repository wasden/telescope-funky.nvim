local debug = require('funky').debug()
local M = {}

local function match_rules(rules, ltext)
  for col_idx, regex_rule in pairs(rules) do
    local matched_result = string.match(ltext, regex_rule)
    if matched_result ~= nil then
      return col_idx, matched_result
    end
  end
  return nil, nil
end

-- @table rules col_idx=kind
-- @return col_idx={ text, lnum }
M.make_result = function (rules)
  local results = {}
  for col_idx, _ in pairs(rules) do
      results[col_idx] = {}
  end
  local all_buf_lines = vim.api.nvim_buf_get_lines(0,0,-1,false)
  for lnum, ltext in ipairs(all_buf_lines) do
    local col_idx, matched_result = match_rules(rules, ltext)
    if col_idx == nil or matched_result == nil then
      goto no_match
    end
    table.insert(results[col_idx], {
      text = matched_result,
      lnum = lnum
    })

    ::no_match::
  end
  debug("regex_results:", results)
  return results
end

return M
