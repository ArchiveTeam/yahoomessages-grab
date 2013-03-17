
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
  local urls = {}

  -- threads on a board
  local base, board_num = string.match(url, "^(http://messages%.yahoo%.com/.+)/forumview%?bn=([^&]+)")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- threads on this page
    for u in string.gmatch(html, "class=\"syslink\" href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=tm&bn="..board_num.."&tid=%d+&mid=[^\"]+)\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end

    -- next, previous page
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/forumview%?bn="..board_num.."[^\"]*)\"><span class=\"pagination\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end

  -- messages in a thread
  local base, board_num, thread_id, message_id = string.match(url, "^(http://messages%.yahoo%.com/.+)/threadview%?m=tm&bn=([^&]+)&tid=(%d+)&mid=(-?%d+)&")
  if base then
    local html = read_file(file)
    board_num = escape_lua_pattern(board_num)

    -- other messages on this page
    for u in string.gmatch(html, "class=\"syslink\" href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=tm&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end

    -- next, previous page
    for u in string.gmatch(html, "href=\"(http://messages%.yahoo%.com/[^\"]+/threadview%?m=tm&bn="..board_num.."&tid="..thread_id.."&mid=[^\"]+)\"><span class=\"pagination\"") do
      table.insert(urls, { url=u, link_expect_html=1 })
    end
  end
  
  return urls
end

