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

  def payload_template
    get_setting('payload_template')
  end

  def slack_webhook_url
    get_setting('webhook_url')
  end

  def slack_webhook_retries
    # The number of retries to deliver the payload to the slack webhook
    get_setting('webhook_retries') || 5
  end

  def slack_webhook_timeout
    # The amount of time (in seconds) to give for the webhook request to complete before failing it
    get_setting('webhook_timeout') || 10
  end

  def slack_webhook_retry_sleep
    # The amount of time (in seconds) to wait in between webhook retries
    get_setting('webhook_retry_sleep') || 5
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

  def slack_link_names
    get_setting('link_names')
  end

  def message_template
    get_setting('template') || get_setting('message_template')
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

  def dashboard_uri
    get_setting('dashboard')
  end

  def incident_key
    if dashboard_uri.nil?
      @event['client']['name'] + '/' + @event['check']['name']
    else
      "<#{dashboard_uri}#{@event['client']['name']}?check=#{@event['check']['name']}|#{@event['client']['name']}/#{@event['check']['name']}>"
    end
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  rescue TypeError, NoMethodError => e
    puts "settings: #{settings}"
    puts "slack key: #{config[:json_config]}. This should not be a file name/path."
    puts <<-EOS
      key name: #{name}. This is the key in config that broke.
      Check the slack key to make sure it's parent key exists"
      EOS
    puts "error: #{e.message}"
    exit 3 # unknown
  end

  def handle
    if payload_template.nil?
      description = @event['check']['notification'] || build_description
      post_data("#{incident_key}: #{description}")
    else
      post_data(render_payload_template(slack_channel))
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
                   @event["client"]["address"],
                   @event["client"]["subscriptions"].join(",")
                 ].join(" : ")
                 %>
                 '''
               end
    eruby = Erubis::Eruby.new(template)
    eruby.result(binding)
  end

  def post_data(body)
    uri = URI(slack_webhook_url)
    http = if proxy_address.nil?
             Net::HTTP.new(uri.host, uri.port)
           else
             Net::HTTP::Proxy(proxy_address, proxy_port, proxy_username, proxy_password).new(uri.host, uri.port)
           end
    http.use_ssl = true

    # Implement a retry-timeout strategy to handle slack api issues like network. Should solve #15
    begin # retries loop
      tries = slack_webhook_retries
      Timeout.timeout(slack_webhook_timeout) do

        begin # main loop for trying to deliver the message to slack webhook
          req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}", 'Content-Type' => 'application/json')

          if payload_template.nil?
            text = slack_surround ? slack_surround + body + slack_surround : body
            req.body = payload(text).to_json
          else
            req.body = body
          end

          response = http.request(req)

        # replace verify_response with a rescue within the loop
        rescue Net::HTTPServerException => error
          if (tries -= 1) > 0
            sleep slack_webhook_retry_sleep
            puts "retrying incident #{incident_key}... #{tries} left"
            retry
          else
            # raise error for sensu-server to catch and log
            puts 'slack api failed (retries) ' + incident_key + ' : ' + error.response.code + ' ' + error.response.message + ': sending to channel "' + slack_channel + '" the message: ' + body
            exit 1
          end
        end # of main loop for trying to deliver the message to slack webhook

      end # of timeout:do loop

    # if the timeout is exceeded, consider this try failed
    rescue Timeout::Error
      if (tries -= 1) > 0
        puts "timeout hit, retrying... #{tries} left"
        retry
      else
        # raise error for sensu-server to catch and log
        puts 'slack webhook failed (timeout) ' + incident_key + ' : sending to channel "' + slack_channel + '" the message: ' + body
        exit 1
      end
    end # of retries loop

  end # of post_data

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
      icon_url: slack_icon_url ? slack_icon_url : 'https://raw.githubusercontent.com/sensu/sensu-logo/master/sensu1_flat%20white%20bg_png.png',
      attachments: [{
        title: "#{@event['client']['address']} - #{translate_status}",
        text: [slack_message_prefix, notice].compact.join(' '),
        color: color,
        fields: client_fields
      }]
    }.tap do |payload|
      payload[:channel] = slack_channel if slack_channel
      payload[:username] = slack_bot_name if slack_bot_name
      payload[:icon_emoji] = slack_icon_emoji if slack_icon_emoji
      payload[:link_names] = slack_link_names if slack_link_names
    end
  end

  def color
    color = {
      0 => '#36a64f',
      1 => '#FFCC00',
      2 => '#FF0000',
      3 => '#6600CC'
    }
    begin
      color.fetch(check_status.to_i)
    # a script can return any error code it feels like we should not assume
    # that it will always be 0,1,2,3 even if that is the sensu (nagions)
    # specification. A couple common examples:
    # 1. A sensu server schedules a check on the instance but the command
    # executed does not exist in your `$PATH`. Shells will return a `127` status
    # code.
    # 2. Similarly a `126` is a permission denied or the command is not
    # executable.
    # Rather than adding every possible value we should just treat any non spec
    # designated status code as `unknown`s.
    rescue KeyError
      color.fetch(3)
    end
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
    begin
      status.fetch(check_status.to_i)
    # handle any non standard check status as `unknown`
    rescue KeyError
      status.fetch(3)
    end
  end
end
