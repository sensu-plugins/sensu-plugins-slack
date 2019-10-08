## Sensu-Plugins-slack

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-slack.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-slack)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-slack.svg)](https://badge.fury.io/rb/sensu-plugins-slack)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-slack/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-slack)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-slack/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-slack)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-slack.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-slack)
[![Community Slack](https://slack.sensu.io/badge.svg)](https://slack.sensu.io/badge)


## Functionality

## Files
 * bin/handler-slack.rb
 * bin/handler-slack-multichannel.rb

## Usage for handler-slack.rb
```
{
  "slack": {
    "webhook_url": "webhook url",
    "dashboard": "uchiwa url, add link to slack notification. Format: http://sensu.com/#/client/$DataCenter/, optional",
    "channel": "#notifications-room, optional defaults to slack defined",
    "message_prefix": "optional prefix - can be used for mentions",
    "surround": "optional - can be used for bold(*), italics(_), code(`) and preformatted(```)",
    "bot_name": "optional bot name, defaults to slack defined",
    "link_names": "optional - find and link channel names and usernames",
    "message_template": "optional description erb template file - /some/path/to/template.erb",
    "payload_template": "optional json payload template file (note: overrides most other template options.)",
    "template": "backwards-compatible alias for message_template",
    "proxy_address": "The HTTP proxy address (example: proxy.example.com)",
    "proxy_port": "The HTTP proxy port (if there is a proxy)",
    "proxy_username": "The HTTP proxy username (if there is a proxy)",
    "proxy_password": "The HTTP proxy user password (if there is a proxy)",
    "icon_url": "https://raw.githubusercontent.com/sensu/sensu-logo/master/sensu1_flat%20white%20bg_png.png",
    "icon_emoji": ":snowman:",
    "fields": [
      "list",
      "of",
      "optional",
      "clientkeys",
      "to_render"
    ]
  }
}
```
## Usage for handler-slack-multichannel.rb
```
{
  "slack": {
    "webhook_urls": {
      "default": "https://hooks.slack.com/services/AAAAAAA"
      "no-team-alerts": "https://hooks.slack.com/services/BBBBBB",
      "all-alerts": "https://hooks.slack.com/services/CCCCCC"
    },
    "channels": {
      "default": [ "no-team-alerts" ],
      "compulsory": [ "all-alerts" ]
    }
    "message_prefix": "optional prefix - can be used for mentions",
    "surround": "optional - can be used for bold(*), italics(_), code(`) and preformatted(```)",
    "bot_name": "optional bot name, defaults to slack defined",
    "link_names": "optional - find and link channel names and usernames",
    "message_template": "optional description erb template file - /some/path/to/template.erb",
    "payload_template": "optional json payload template file (note: overrides most other template options.)",
    "template": "backwards-compatible alias for message_template",
    "proxy_address": "The HTTP proxy address (example: proxy.example.com)",
    "proxy_port": "The HTTP proxy port (if there is a proxy)",
    "proxy_username": "The HTTP proxy username (if there is a proxy)",
    "proxy_password": "The HTTP proxy user password (if there is a proxy)",
    "icon_url": "https://raw.githubusercontent.com/sensu/sensu-logo/master/sensu1_flat%20white%20bg_png.png",
    "icon_emoji": ":snowman:",
    "custom_field": [
      "list",
      "of",
      "optional",
      "check_fields",
      "to_render"
    ]
  }
}
```


## Installation

[Installation and Setup](https://sensu-plugins.io/docs/installation_instructions.html)

## Notes

### payload_template example

```
{
  "username": "sensu alarms",
  "icon_emoji": ":bell:",
  "channel": channel,
  "attachments": [
    {
      "fallback": "<%= @event["check"]["output"].gsub('"', '\\"') %>",
      "color": "<%= color %>",
      "title": "<%= @event["check"]["name"] %> (<%= @event["client"]["name"] %>)",
      "text": "<%= @event["check"]["output"].gsub('"', '\\"') %>"
    }
  ]
}
```

You can also use `to_json`

```
<%=
  {
    :text => "Some text"
  }.to_json
-%>
```

See https://api.slack.com/incoming-webhooks and https://api.slack.com/docs/attachments
