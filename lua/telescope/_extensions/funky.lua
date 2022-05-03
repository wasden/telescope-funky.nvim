local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local actions = require "telescope.actions"
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')
local strdisplaywidth = require('plenary.strings').strdisplaywidth
local config = require('funky').config
local debug = require('funky').debug()
local treesitter = require('treesitter')
local regex = require('regex')


local function make_results(rules)
  local rule_cnt = #rules
  debug("config:", rules)

  -- @return table {col_idx, rule}
  -- @return table {col_idx, rule}
  local function classify_rules()
    local regex_rules = {}
    local treesitter_rules = {}

    -- idx in rules is col_idx in display layout
    for col_idx, rule in ipairs(rules) do
      if rule.treesitter_kind ~= nil then
        treesitter_rules[col_idx] = rule.treesitter_kind
        goto finish
      end
      if rule.regex ~= nil then
        regex_rules[col_idx] = rule.regex
        goto finish
      end
      error("cannot find regex and treesitter_kind")
      ::finish::
    end
    return regex_rules, treesitter_rules
  end
  local function merge_rule_results(treesitter_results, regex_results)
    local results = {}
    for i = 1, rule_cnt do
      results[i] = treesitter_results[i] or regex_results[i]
    end
    return results
  end

  -- @table { col_idx={ text, lnum } }
  -- @return { row_idx={ row_data } }
  local function merge_column_results(column_results)
    local sort_results = {}
    for col_idx, results in ipairs(column_results) do
      for _, result in ipairs(results) do
        table.insert(sort_results, {
          col_idx = col_idx,
          text = result.text,
          lnum = result.lnum,
        })
      end
    end
    table.sort(sort_results, function (element1, element2)
      if element1.lnum < element2.lnum then
        return true
      elseif element1.lnum > element2.lnum then
        return false
      end
      return element1.col_idx < element2.col_idx
    end)
    return sort_results
  end

  local function cache_save(cache)
    local cache_copy = {}
    for i = 1, rule_cnt do
      cache_copy[i] = cache[i]
    end
    return cache_copy
  end

  local function make_sortable_text(display_cache)
    local sortable_text = ""
    for idx, text in ipairs(display_cache) do
      if rules[idx].sortable == nil or rules[idx].sortable then
        sortable_text = sortable_text .. text
      end
    end
    return sortable_text
  end

  local function set_col_width(col_idx, str)
    if rules[col_idx].fixed_width ~= nil then
      return
    end

    local display_width = strdisplaywidth(str)
    if rules[col_idx].width == nil or
      display_width > rules[col_idx].width then
      rules[col_idx].width = display_width
    end
  end

  local function make_results_for_display(row_results)
    local results = {}
    local filename = vim.fn.expand(vim.api.nvim_buf_get_name(0))
    local display_hierarchy_cache = {}
    for i = 1, rule_cnt do
      display_hierarchy_cache[i] = ""
    end

    for _, row_data in ipairs(row_results) do

      -- clean low level rules cache
      for i = row_data.col_idx + 1, #rules do
        display_hierarchy_cache[i] = ""
      end

      display_hierarchy_cache[row_data.col_idx] = row_data.text
      set_col_width(row_data.col_idx, row_data.text)

      if not rules[row_data.col_idx].selectable then
        goto unselectable
      end

      table.insert(results, {
        lnum = row_data.lnum,
        filename = filename,
        texts = cache_save(display_hierarchy_cache),
        sortable_text = make_sortable_text(display_hierarchy_cache),
      })

      ::unselectable::
    end
    return results
  end


  local regex_rules, treesitter_rules = classify_rules()
  local column_results = merge_rule_results(
    treesitter.make_results(treesitter_rules),
    regex.make_result(regex_rules)
  )
  debug("columns results:", column_results)
  if #column_results ~= rule_cnt then
    error(string.format("missed rule, before rule_cnt:%s, after rule_cnt:%s",
      rule_cnt, #column_results))
  end

  local row_results = merge_column_results(column_results)
  debug("row_results:", row_results)

  return make_results_for_display(row_results)
end

local function make_current_pos(results)
  local current_pos = 1
  local cursor_idx, _ = unpack(vim.api.nvim_win_get_cursor(0))
  for idx, line in ipairs(results) do
    if cursor_idx < line.lnum then
      break
    end
    current_pos = idx
  end
  return current_pos
end

local function make_display(entry)
  local layout = {}
  local row_data = {}
  local rules = entry.rules

  layout[1] = { width = 7 }
  if entry.index == entry.current_pos then
    row_data[1] = " " .. entry.lnum
  else
    row_data[1] = "  " .. entry.lnum
  end

  for idx, rule in pairs(rules) do
    if idx == #rules then
      layout[idx + 1] = { remaining = true }
    else
      layout[idx + 1] = { width = rule.fixed_width or rule.width}
    end
      row_data[idx + 1] = entry.value[idx]
  end

  local displayer = entry_display.create {
    separator = " │",
    items = layout,
  }
  return displayer(row_data)
end

local function funky(opts)
  opts = opts or {}
  local rules = assert(
    config[vim.bo.filetype],
    string.format('Current filetype %s is not configured.', vim.bo.filetype)
  )

  local results = make_results(rules)
  local current_pos = make_current_pos(results)

  pickers.new(opts, {
    prompt_title = "Funky",
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          valid = true,
          value = entry.texts,
          ordinal = entry.sortable_text,
          display = make_display,
          filename = entry.filename,
          lnum = entry.lnum,
          current_pos = current_pos,
          rules = rules,
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
      end)
      return true
    end,
    default_selection_index = current_pos,
    scroll_strategy = 'limit',
  }):find()
end

return require("telescope").register_extension({
  exports = {
    funky = funky,
  },
})
