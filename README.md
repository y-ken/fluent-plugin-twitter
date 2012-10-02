fluent-plugin-twitter
=====================

## Overview
create your own twitter bot with fluentd

## Installation

### native gem

`````
gem install fluent-plugin-twitter
`````

### td-agent gem
`````
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-twitter
`````

## Configuration

### Sample
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

## Debug
`````
$ curl http://localhost:8888/notify.twitter -F 'json={"message":"foo"}'
`````

## Reference

### Twitter OAuth Guide
http://pocketstudio.jp/log3/2012/02/12/how_to_get_twitter_apikey_and_token/

## TODO
patches welcome!

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
