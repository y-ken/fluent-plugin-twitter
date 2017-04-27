fluent-plugin-twitter [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-twitter.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-twitter)
=====================

## Component
Fluentd Input/Output plugin to process tweets with Twitter Streaming API.

## Dependency

before use, install dependent library as:

```
# for RHEL/CentOS (eventmachine requires build dependency)
$ sudo yum -y install gcc gcc-c++ openssl-devel libcurl libcurl-devel

# for Ubuntu/Debian (eventmachine requires build dependency)
$ sudo apt-get install build-essential libssl-dev
```

## Requirements

| fluent-plugin-twitter | fluentd    | ruby   |
|--------------------|------------|--------|
|  0.6.1            | v0.14.x | >= 2.1 |
|  0.5.4            | v0.12.x | >= 1.9 |

## Installation

install with `gem` or `td-agent-gem` command as:

```
# for fluentd
$ gem install eventmachine
$ gem install fluent-plugin-twitter

# for td-agent2
$ sudo td-agent-gem install eventmachine
$ sudo td-agent-gem install fluent-plugin-twitter -v 0.5.4
```

## Input Configuration

### Input Sample

It require td-agent2 (fluentd v0.12) to use keyword with hashtag.

`````
<source>
  @type twitter
  consumer_key        YOUR_CONSUMER_KEY        # Required
  consumer_secret     YOUR_CONSUMER_SECRET     # Required
  access_token        YOUR_ACCESS_TOKEN        # Required
  access_token_secret YOUR_ACCESS_TOKEN_SECRET # Required
  tag                 input.twitter.sampling   # Required
  timeline            tracking                 # Required (tracking or sampling or location or userstream)
  keyword             'Ruby,Python,#fleuntd'   # Optional (keyword has priority than follow_ids)
  follow_ids          14252,53235              # Optional (integers, not screen names)
  locations           31.110283, 129.431631, 45.619283, 145.510175  # Optional (bounding boxes; first pair specifies longitude/latitude of southwest corner)
  lang                ja,en                    # Optional
  output_format       nest                     # Optional (nest or flat or simple[default])
  flatten_separator   _                        # Optional
</source>

<match input.twitter.sampling>
  @type stdout
</match>
`````

### Proxy support

```
<source>
  @type twitter
  consumer_key        YOUR_CONSUMER_KEY        # Required
  consumer_secret     YOUR_CONSUMER_SECRET     # Required
  access_token        YOUR_ACCESS_TOKEN        # Required
  access_token_secret YOUR_ACCESS_TOKEN_SECRET # Required
  tag                 input.twitter.sampling   # Required
  timeline            tracking                 # Required (tracking or sampling or location or userstream)
  <proxy>
    host proxy.example.com                     # Required
    port 8080                                  # Required
    username proxyuser                         # Optional
    password proxypass                         # Optional
  </proxy>
</source>
```

### Testing

`````
$ tail -f /var/log/td-agent/td-agent.log
`````

## Output Configuration

### Output Sample
`````
<source>
  @type http
  port 8888
</source>

<match notify.twitter>
  @type twitter
  consumer_key        YOUR_CONSUMER_KEY
  consumer_secret     YOUR_CONSUMER_SECRET
  access_token        YOUR_ACCESS_TOKEN
  access_token_secret YOUR_ACCESS_TOKEN_SECRET
</match>
`````

### Proxy support

```
<match notify.twitter>
  @type twitter
  consumer_key        YOUR_CONSUMER_KEY
  consumer_secret     YOUR_CONSUMER_SECRET
  access_token        YOUR_ACCESS_TOKEN
  access_token_secret YOUR_ACCESS_TOKEN_SECRET
  <proxy>
    host proxy.example.com
    port 8080
    username proxyuser
    password proxypass
  </proxy>
</match>
```

### Testing

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
