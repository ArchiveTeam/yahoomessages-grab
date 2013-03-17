#!/bin/bash
http_proxy=localhost:8123 \
./wget-lua-local \
  -nv \
  -U "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22" \
  --output-document t.html \
  --truncate-output \
  -e "robots=off" \
  --lua-script yahoo-messages.lua \
  --header "Cookie: YMBP1=view=tm|ratingTView=1|ratingTot=1" \
  --warc-file t3 \
  "http://messages.yahoo.com/Science/Astronomy/forumview?bn=18934669"
# "http://messages.yahoo.com/Cultures_%26_Community/Crime/threadview?m=tm&bn=18077660%23policebashing&tid=1391&mid=1391&tof=48&rt=1&frt=1&off=1"
# "http://messages.yahoo.com/Science/Astronomy/threadview?m=tm&bn=18934669&tid=556&mid=556&tof=8&frt=1"

