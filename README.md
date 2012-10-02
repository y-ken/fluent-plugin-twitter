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
<match notify.twitter>
  type twitter
  consumer_key        YOUR_CONSUMER_KEY
  consumer_secret     YOUR_CONSUMER_SECRET
  oauth_token         YOUR_OAUTH_TOKEN
  oauth_token_secret  YOUR_OAUTH_TOKEN_SECRET
</match>
`````

## TODO
patches welcome!

## Copyright

Copyright © 2012- Kentaro Yoshida (@yoshi_ken)

## License

Apache License, Version 2.0
