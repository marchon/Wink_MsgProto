#! /usr/bin/ruby 

require 'rubygems'
require 'bundler/setup'
require 'mqtt'
require_relative 'winkwrapper'

debug = ARGV[0] == "-v"
wink = WinkWrapper.new debug

# Subscribe example
MQTT::Client.connect('localhost') do |c|
    puts "Connected to MQTT" if debug

    # If you pass a block to the get method, then it will loop
    # Topic Format: /winknet/<device_type>/<id>/<action>/<remote_api?>
    c.get('/winknet/#') do |topic, message|
        puts "#{topic}: #{message}" if debug

        topic = topic.slice 9..topic.length # Remove /winknet/
        device_type, id, action, remote_api = topic.split "/"

        remote_api = remote_api == "remote"

        if topic.to_sym == :list_all
            wink.list_all
        else
            case device_type.to_sym
            when :light_bulb
                case action.to_sym
                when :on
                    wink.light_on id, :remote_api => remote_api
                when :off
                    wink.light_off id, :remote_api => remote_api
                when :dim, :dim_to_percent, :dim_by_delta
                    _, dim_type = action.split "_", 2
                    dim_type = "" if dim_type.nil?
                    wink.light_dim id, message, :dim_type => dim_type.to_sym, :remote_api => remote_api
                end
            end
        end
    end
end
