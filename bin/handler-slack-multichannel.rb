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
# { "handlers":
#     "slack": {
#       "channels" {
#         "default": [ "#no-team-alerts" ],
#         "compulsory": [ "#all-alerts" ],
#        }
#     }
# }
#
# Alerts are always sent to the compulsory channel(s).
#
# Alerts are sent to default channels if no channels are configured
# in the check config.
#
# Check specific channels:
#
# { "checks":
#     "check_my_db": {
#       "handlers": [ "default", "slack" ],
#       "slack" {
#         "channels" [ "#db-team-alerts" ]
#       }
#       ...,
#     }
# }

require 'sensu-handler'
require 'json'

class Slack < Sensu::Handler
  option :json_config,
         description: 'Configuration name',
         short: '-j JSONCONFIG',
         long: '--json JSONCONFIG',
         default: 'slack'

  def slack_webhook_url
    get_setting('webhook_url')
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

  def compile_channel_list
    channels = []

    if check_configured_channels
      channels = check_configured_channels
      puts "using check configured channels: #{channels.join('.').chomp(',')}"
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
      puts 'nno channels found'
      return
    end

    notice = build_notice

    slack_channels.each do |channel|
      puts "#{channel}: #{notice}"
      post_data(notice, channel)
    end
  end

  def post_data(notice, channel)
    uri = URI(slack_webhook_url)

    if (defined?(slack_proxy_addr)).nil?
      http = Net::HTTP.new(uri.host, uri.port)
    else
      http = Net::HTTP::Proxy(slack_proxy_addr, slack_proxy_port).new(uri.host, uri.port)
    end

    http.use_ssl = true

    begin
      req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}")
      text = slack_surround ? slack_surround + notice + slack_surround : notice
      req.body = payload(text, channel).to_json

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
      fail response.error!
    end
  end

  def payload(notice, channel)
    {
      icon_url: 'http://sensuapp.org/img/sensu_logo_large-c92d73db.png',
      attachments: [{
        text: [slack_message_prefix, notice].compact.join(' '),
        color: color
      }]
    }.tap do |payload|
      payload[:channel] = channel
      payload[:username] = slack_bot_name if slack_bot_name
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
end
