#!/usr/bin/env ruby

# Copyright 2014 Dan Shultz and contributors.
# Multichannel support added in 2015 by Rob Wilson
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# In order to use this plugin, you must first configure an incoming webhook
# integration in slack. You can create the required webhook by visiting
# https://{your team}.slack.com/services/new/incoming-webhook
#
# After you configure your webhook, you'll need the webhook URL from the integration.
#
# Multi-channel support:
#
# Default channels and compulsory channels can be set in the handler config:
#
# { "handlers": {
#     "slack": {
#       "channels" {
#         "default": [ "#no-team-alerts" ],
#         "compulsory": [ "#all-alerts" ],
#        }
#     },
#     ...,
#   }
# }
#
# Alerts are always sent to the compulsory channel(s).
#
# Alerts are sent to default channels if no channels are configured
# in the client config or check config.
#
# If channels are defined on the client, they will override the defaults:
#
# { "client":{
#     "name": "Appserver"
#     "slack" {
#       "channels" [ "#appserver-team-alerts" ]
#     },
#     ...,
#   }
# }
#
# If channels are defined on a check, they will override anything defined on
# the client or the defaults:
#
# { "checks": {
#     "check_my_db": {
#       "handlers": [ "default", "slack" ],
#       "slack" {
#         "channels" [ "#db-team-alerts" ]
#       },
#       ...,
#     }
#   }
# }
#
# Custom Field support added:
#
# Adding custom_field to handler will add a field to message with that fields content, if that field doesn't exist it will be ignored.
#
#       "slack" {
#         "channels" [ "#db-team-alerts" ],
#         "custom_field" [
#           "field_name",
#           "field_name_2"
#         ]
#        }
#
# On your check.json
#
# {
#   "checks": {
#     "check_disk_usage": {
#        "command": " ~/check-disk-usage.rb -w 90 -c 95",
#        "field_name": "https://someurl.somewhere",
#        "field_name_2: "something_you_want_added"

require 'sensu-handler'
require 'json'
require 'erubis'

class Slack < Sensu::Handler
  option :json_config,
         description: 'Configuration name',
         short: '-j JSONCONFIG',
         long: '--json JSONCONFIG',
         default: 'slack'

  def payload_template
    get_setting('payload_template')
  end

  def message_template
    get_setting('template') || get_setting('message_template')
  end

  def slack_icon_url
    get_setting('icon_url')
  end

  def slack_icon_emoji
    get_setting('icon_emoji')
  end

  def slack_proxy_addr
    get_setting('proxy_addr')
  end

  def slack_proxy_port
    get_setting('proxy_port')
  end

  def slack_message_prefix
    get_setting('message_prefix')
  end

  def slack_bot_name
    get_setting('bot_name')
  end

  def slack_surround
    get_setting('surround')
  end

  def webhook_urls
    get_setting('webhook_urls')
  end

  def default_channels
    return get_setting('channels')['default']
  rescue
    return []
  end

  def compulsory_channels
    return get_setting('channels')['compulsory']
  rescue
    return false
  end

  def check_configured_channels
    return @event['check']['slack']['channels']
  rescue
    return false
  end

  def client_configured_channels
    return @event['client']['slack']['channels']
  rescue
    return false
  end

  def custom_field
    get_setting('custom_field')
  end

  def compile_channel_list
    channels = []

    if check_configured_channels
      channels = check_configured_channels
      puts "using check configured channels: #{channels.join('.').chomp(',')}"
    elsif client_configured_channels
      channels = client_configured_channels
      puts "using client configured channels: #{channels.join('.').chomp(',')}"
    else
      channels = default_channels
      puts "using check default channels: #{default_channels.join(',').chomp(',')}"
    end

    if compulsory_channels
      channels |= compulsory_channels
      puts "adding compulsory channels: #{compulsory_channels.join(',').chomp(',')}"
    end

    puts "target channels: #{channels.join(',').chomp(',')}"

    channels
  end

  def slack_channels
    @channels ||= compile_channel_list
  end

  def markdown_enabled
    get_setting('markdown_enabled') || true
  end

  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def build_notice
    "#{@event['check']['status'].to_s.rjust(3)} | #{incident_key}: #{@event['check']['output'].strip}"
  end

  def handle
    unless slack_channels.is_a?(Array)
      puts 'no channels found'
      return
    end

    notice = build_notice

    slack_channels.each do |channel|
      if payload_template.nil?
        notice = @event['notification'] || build_description
        post_data(notice, channel)
      else
        post_data(render_payload_template(channel), channel)
      end
    end
  end

  def render_payload_template(channel)
    return unless payload_template && File.readable?(payload_template)
    template = File.read(payload_template)
    eruby = Erubis::Eruby.new(template)
    eruby.result(binding)
  end

  def build_description
    template = if message_template && File.readable?(message_template)
                 File.read(message_template)
               else
                 '''<%=
                 [
                   @event["check"]["output"].gsub(\'"\', \'\\"\'),
                   @event["client"]["name"],
                   @event["client"]["subscriptions"].join(",")
                 ].join(" : ")
                 %>
                 '''
               end
    eruby = Erubis::Eruby.new(template)
    eruby.result(binding)
  end

  def post_data(notice, channel)
    slack_webhook_url = webhook_urls[channel]
    uri = URI(slack_webhook_url)

    http = if defined?(slack_proxy_addr).nil?
             Net::HTTP.new(uri.host, uri.port)
           else
             Net::HTTP::Proxy(slack_proxy_addr, slack_proxy_port).new(uri.host, uri.port)
           end

    http.use_ssl = true

    begin
      req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}")
      if payload_template.nil?
        text = slack_surround ? slack_surround + notice + slack_surround : notice
        req.body = payload(text, channel).to_json
      else
        req.body = notice
      end
      puts "request: #{req}"

      response = http.request(req)

      puts "response: #{response}"

      verify_response(response)
    rescue => error
      puts "error making http request: #{error}"
    end
  end

  def verify_response(response)
    case response
    when Net::HTTPSuccess
      true
    else
      raise response.error!
    end
  end

  def payload(notice, channel)
    client_fields = []

    unless custom_field.nil?
      custom_field.each do |field|
        is_short = true unless @event['client'].key?(field) && @event['client'][field].length > 50
        field_title = field unless @event['check'][field].nil?
        client_fields << {
          title: field_title,
          value: @event['check'][field],
          short: is_short
        }
      end
    end
    {
      icon_url: slack_icon_url ? slack_icon_url : 'https://raw.githubusercontent.com/sensu/sensu-logo/master/sensu1_flat%20white%20bg_png.png',
      attachments: [{
        title: "#{@event['client']['name']} - #{translate_status}",
        text: [slack_message_prefix, notice].compact.join(' '),
        color: color,
        fields: client_fields
      }]
    }.tap do |payload|
      payload[:channel] = channel
      payload[:username] = slack_bot_name if slack_bot_name
      payload[:icon_emoji] = slack_icon_emoji if slack_icon_emoji
      payload[:attachments][0][:mrkdwn_in] = %w(text) if markdown_enabled
    end
  end

  def color
    color = {
      0 => '#36a64f',
      1 => '#FFCC00',
      2 => '#FF0000',
      3 => '#6600CC'
    }
    color.fetch(check_status.to_i)
  end

  def check_status
    @event['check']['status']
  end

  def translate_status
    status = {
      0 => :OK,
      1 => :WARNING,
      2 => :CRITICAL,
      3 => :UNKNOWN
    }
    status[check_status.to_i]
  end
end
