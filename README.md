fluent-plugin-twitter
=====================

## Component
Fluentd Input/Output plugin to process tweets with Twitter Streaming API.

## Installation

### native gem

`````
gem install fluent-plugin-twitter
`````

### td-agent gem
`````
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-twitter
`````

## Input Configuration

### Input Sample
`````
<source>
  type twitter
  consumer_key        YOUR_CONSUMER_KEY       # Required
  consumer_secret     YOUR_CONSUMER_SECRET    # Required
  oauth_token         YOUR_OAUTH_TOKEN        # Required
  oauth_token_secret  YOUR_OAUTH_TOKEN_SECRET # Required
  tag                 input.twitter.sampling  # Required
  timeline            sampling                # Required (sampling or userstream)
  keyword             Ruby,Python             # Optional (currently, only work with `timeline` is sampling)
  lang                ja,en                   # Optional
  output_format       nest                    # Optional (nest or flat or simple[default])
</source>

<match input.twitter.sampling>
  type stdout
</match>
`````

### Debug
`````
$ tail -f /var/log/td-agent/td-agent.log
`````

## Output Configuration

### Output Sample
`````
<source>
  type http
  port 8888
</source>

<match notify.twitter>
  type twitter
  consumer_key        YOUR_CONSUMER_KEY
  consumer_secret     YOUR_CONSUMER_SECRET
  oauth_token         YOUR_OAUTH_TOKEN
  oauth_token_secret  YOUR_OAUTH_TOKEN_SECRET
</match>
`````

### Debug
`````
$ curl http://localhost:8888/notify.twitter -F 'json={"message":"foo"}'
`````

## Reference

### Twitter OAuth Guide
http://pocketstudio.jp/log3/2012/02/12/how_to_get_twitter_apikey_and_token/

### Quick Tour to count a tweet with fluent-plugin-twitter and fluent-plugin-datacounter
http://qiita.com/items/fe4258b394190f23fece

## TODO
patches welcome!

## Known Issue
On starting fluentd, appearing alert message below. Please tell me how to fix up.
`/usr/lib64/fluent/ruby/lib/ruby/gems/1.9.1/gems/eventmachine-1.0.0/lib/eventmachine.rb:1530: warning: already initialized constant EM`

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
