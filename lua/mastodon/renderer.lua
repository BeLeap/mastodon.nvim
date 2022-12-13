
local M = {}

local function split_by_chunk(text, chunk_size)
    local s = {}
    for i=1, #text, chunk_size do
        s[#s+1] = text:sub(i, i + chunk_size - 1)
    end
    return s
end

local function is_reblog(status)
  return status['reblog'] ~= vim.NIL
end

M.render_home_timeline = function(bufnr, win, statuses)
  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']

  local lines = {}
  local metadata = {}

  local line_number = 0
  local line_numbers = {}

  for i, status in ipairs(statuses) do
    local target_status = nil
    local line = nil
    local account = status['account']
    if is_reblog(status) then
      target_status = status['reblog']
      line = "@" .. target_status['account']['username']
      line = line .. "(" .. target_status['account']['display_name']  .. ")"
      line = line .. " --- boosted by @" .. account['username']
      line = line .. "(" .. (account['display_name']) .. ")"
    else
      target_status = status
      line = "@" .. account['username']
      line = line .. "(" .. (account['display_name']) .. ")"
    end
    local status_id = status['id']
    local url = status['uri']
    local json = vim.fn.json_encode({
      status_id = status_id,
      url = url,
    })

    table.insert(lines, line)
    table.insert(line_numbers, line_number)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1

    local whole_message = target_status['content']
    local width = vim.api.nvim_win_get_width(win)

    -- (width - 10) interpolates sign column's length and line number column's length
    local chunks = split_by_chunk(whole_message, width - 10)
    for i, chunk in ipairs(chunks) do
      table.insert(lines, chunk)
      table.insert(metadata, {
        line_number = line_number,
        data = json,
      })
      line_number = line_number + 1
    end

    line = '-----------------------'
    table.insert(lines, line)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1
  end

  vim.api.nvim_buf_set_name(bufnr, "Mastodon Home")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "mastodon")
  vim.api.nvim_buf_set_lines(0, 0, 0, 'true', lines)
  vim.api.nvim_win_set_hl_ns(win, mastodon_ns)

  for _, line_number in ipairs(line_numbers) do
    vim.api.nvim_buf_add_highlight(bufnr, mastodon_ns, "MastodonHandle", line_number, 0, -1)
  end

  for _, metadata_for_line in ipairs(metadata) do
    vim.api.nvim_buf_set_extmark(bufnr, mastodon_ns, metadata_for_line.line_number, 0, {
      virt_text = {{metadata_for_line.data, "Whitespace"}},
    })
  end
end

return M