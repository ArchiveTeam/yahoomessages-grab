

local read_file = function(file)
  local f = io.open(file)
  local data = f:read("*all")
  f:close()
  return data
end

local url_count = 0

wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}

  local base, board_num, thread_id, message_id = string.match(url, "^(http://messages%.yahoo%.com/.+)/threadview%?m=tm&bn=(%d+)&tid=(%d+)&mid=(-?%d+)&tof=8&frt=1")
  if base then
    local html = read_file(file)

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
