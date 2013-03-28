
local read_file = function(file)
  local f = io.open(file)
  local data = f:read("*all")
  f:close()
  return data
end

local escape_lua_pattern
do
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }

  escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
  end
end

local url_count = 0

wget.callbacks.get_urls = function(file, url, is_css, iri)
  -- progress message
  url_count = url_count + 1
  if url_count % 10 == 0 then
    io.stdout:write("\r - Downloaded "..url_count.." URLs")
    io.stdout:flush()
  end

  local urls = {}
  local urls_to_delegate = {}

  -- threads on a board
  local base, board_num = string.match(url, "^(http://messages%.yahoo%.com/.+)/forumview%?bn=([^&]+)")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- threads on this page
    for tr in string.gmatch(html, "<tr>.-</tr>") do
      local message_count = string.match(tr, "<td class=\"cell%-no%-highlight\" nowrap=\"true\">%s+(%d+)%s+</td>")
      local thread_urls = ""
      for u in string.gmatch(tr, "class=\"syslink\" href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=tm&bn="..board_num.."&tid=%d+&mid=[^\"]+)\"") do
        thread_urls = thread_urls.." "..string.gsub(u, "%s", "%%20")
      end
      if message_count and #thread_urls > 0 then
        table.insert(urls_to_delegate, message_count..thread_urls)
      end
    end

    -- next, previous page
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/forumview%?bn="..board_num.."[^\"]*)\"><span class=\"pagination\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end

  -- messages in a thread (thread view)
  local base, board_num, thread_id, message_id = string.match(url, "^(http://messages%.yahoo%.com/.+)/threadview%?m=tm&bn=([^&]+)&tid=(%d+)&mid=(-?%d+)&")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- immediately go to the message list view
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=mm&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\">[^<]+Msg List") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end

  -- messages in a thread (message list view)
  local base, board_num, thread_id, message_id = string.match(url, "^(http://messages%.yahoo%.com/.+)/threadview%?m=mm&bn=([^&]+)&tid=(%d+)&mid=(-?%d+)&")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- immediately go to the message list view
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=me&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\">[^<]+Expanded") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end

  -- messages in a thread (expanded message list view)
  local base, board_num, thread_id, message_id = string.match(url, "^(http://messages%.yahoo%.com/.+)/threadview%?m=me&bn=([^&]+)&tid=(%d+)&mid=(-?%d+)&")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- other messages on this page
    for u in string.gmatch(html, "class=\"syslink\" href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=me&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end

    -- next, previous page
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=me&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\"><span class=\"pagination\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end
  
  if #urls_to_delegate > 0 then
    local filename = os.getenv("DELEGATED_URLS_FILENAME")
    if filename then
      local f = io.open(filename, "a")
      for i,url in ipairs(urls_to_delegate) do
        f:write(url.."\n")
      end
      f:close()
    end
  end

  return urls
end


wget.callbacks.httploop_result = function(url, err, http_stat)
  if http_stat.statcode == 999 then
    -- try again
    io.stdout:write("\nRate limited. Waiting for 300 seconds...\n")
    io.stdout:flush()
    os.execute("sleep 300")
    return wget.actions.CONTINUE
  else
    return wget.actions.NOTHING
  end
end

