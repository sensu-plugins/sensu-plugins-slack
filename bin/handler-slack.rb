#!/usr/bin/env ruby

# Copyright 2014 Dan Shultz and contributors.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# In order to use this plugin, you must first configure an incoming webhook
# integration in slack. You can create the required webhook by visiting
# https://{your team}.slack.com/services/new/incoming-webhook
#
# After you configure your webhook, you'll need the webhook URL from the integration.

require 'sensu-handler'
require 'json'
require 'erubis'

class Slack < Sensu::Handler
  option :json_config,
         description: 'Configuration name',
         short: '-j JSONCONFIG',
         long: '--json JSONCONFIG',
         default: 'slack'

  def slack_webhook_url
    get_setting('webhook_url')
  end

  def slack_icon_emoji
    get_setting('icon_emoji')
  end

  def slack_icon_url
    get_setting('icon_url')
  end

  def slack_channel
    @event['client']['slack_channel'] || @event['check']['slack_channel'] || get_setting('channel')
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

  def message_template
    get_setting('template')
  end

  def fields
    get_setting('fields')
  end

  def proxy_address
    get_setting('proxy_address')
  end

  def proxy_port
    get_setting('proxy_port')
  end

  def proxy_username
    get_setting('proxy_username')
  end

  def proxy_password
    get_setting('proxy_password')
  end

  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def handle
    description = @event['notification'] || build_description
    post_data("#{incident_key}: #{description}")
  end

  def build_description
    if message_template && File.readable?(message_template)
      template = File.read(message_template)
    else
      template = '''<%=
      [
        @event["check"]["output"].gsub(\'"\', \'\\"\'),
        @event["client"]["address"],
        @event["client"]["subscriptions"].join(",")
      ].join(" : ")
      %>
      '''
    end
    eruby = Erubis::Eruby.new(template)
    eruby.result(binding)
  end

  def post_data(notice)
    uri = URI(slack_webhook_url)
    http = if proxy_address.nil?
             Net::HTTP.new(uri.host, uri.port)
           else
             Net::HTTP::Proxy(proxy_address, proxy_port, proxy_username, proxy_password).new(uri.host, uri.port)
           end
    http.use_ssl = true

    req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}", 'Content-Type' => 'application/json')
    text = slack_surround ? slack_surround + notice + slack_surround : notice

    req.body = payload(text).to_json

    response = http.request(req)
    verify_response(response)
  end

  def verify_response(response)
    case response
    when Net::HTTPSuccess
      true
    else
      fail response.error!
    end
  end

  def payload(notice)
    client_fields = []

    unless fields.nil?
      fields.each do |field|
        # arbritary based on what I feel like
        # -vjanelle
        is_short = true unless @event['client'].key?(field) && @event['client'][field].length > 50
        client_fields << {
          title: field,
          value: @event['client'][field],
          short: is_short
        }
      end
    end

    {
      icon_url: slack_icon_url ? slack_icon_url : 'http://sensuapp.org/img/sensu_logo_large-c92d73db.png',
      attachments: [{
        title: "#{@event['client']['name']} - #{translate_status}",
        text: [slack_message_prefix, notice].compact.join(' '),
        color: color,
        fields: client_fields
      }]
    }.tap do |payload|
      payload[:channel] = slack_channel if slack_channel
      payload[:username] = slack_bot_name if slack_bot_name
      payload[:icon_emoji] = slack_icon_emoji if slack_icon_emoji
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
