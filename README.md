fluent-plugin-twitter [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-twitter.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-twitter)
=====================

## Component
Fluentd Input/Output plugin to process tweets with Twitter Streaming API.

## Dependency

before use, install dependent library as:

```bash
# for RHEL/CentOS
$ sudo yum install openssl-devel

# for Ubuntu/Debian
$ sudo apt-get install libssl-dev
```

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
  timeline            tracking                # Required (tracking or sampling or userstream)
  keyword             Ruby,Python             # Optional (keyword is priority than follow_ids)
  follow_ids          14252,53235             # Optional (integers, not screen names)
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
  access_token         YOUR_OAUTH_TOKEN
  access_token_secret  YOUR_OAUTH_TOKEN_SECRET
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

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
