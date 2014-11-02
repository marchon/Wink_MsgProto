require 'wink'
require 'timers'
require_relative 'winklocal'

Wink.configure do |wink|
    wink.client_id     = 'quirky_wink_ios_app'
    wink.client_secret = 'ce609edf5e85015d393e7859a38056fe'
    wink.access_token  = '47ae57fe8e95deafddd094cf4431d3b7'
    wink.refresh_token = '443c6cd7cf1d0baa96ab7582ac3eea8b'
end

class WinkWrapper
    def initialize(debug = false)
        @wink_client = Wink::Client.new 
        @local_wink_client = Wink::LocalClient.new

        @device_cache = { :light_bulbs => {} }
        @timer_group = Timers::Group.new
        @timers = {}
        @debug = debug
    end

    def list_all
        @wink_client.devices.each do |device|
            next if device.nil?

            puts "#{device.name} - id: #{device.id}"
        end
    end

    def light_on(id, opts)
        begin
            lb = light id, opts
            lb.device["last_reading"]["powered"] = true

            lb.on 
            clear_cache lb, opts
        rescue Exception => e
            puts "Error light_on(#{id}) - #{e}"
            return false
        end
    end

    def light_off(id, opts)
        begin
            lb = light id, opts
            lb.device["last_reading"]["powered"] = false

            lb.off 
            clear_cache lb, opts
        rescue Exception => e
            puts "Error light_off(#{id}) - #{e}"
            return false
        end
    end

    def light_dim(id, brightness, opts)
        return if ["ON", "OFF", "INCREASE", "DECREASE"].include? brightness
        begin
            brightness = Float(brightness)

            case opts[:dim_type]
            when :by_delta
                _opts = opts.clone
                _opts[:fetch] = true
                _lb = light id, _opts
                brightness = (_lb.brightness + brightness).round 2
            when :to_percent
                brightness = (brightness / 100.0).round 2
            end

            brightness = 0.0 if brightness <= 0.001
            brightness = 1.0 if brightness >= 0.999

            lb = light id, opts
            lb.device["last_reading"]["brightness"] = brightness

            puts "Dimming to #{brightness} via the API" if @debug
            lb.dim brightness
            lb.on if brightness != 0
            lb.off if brightness == 0
            clear_cache lb, opts
        rescue Exception => e
            puts "Error light_dim(#{id}, #{brightness}) - #{e}"
            return false
        end
    end

    def light(id, opts)
        fetch = opts.fetch :fetch, false
        remote_api = opts.fetch :remote_api, false

        if @device_cache[:light_bulbs][id].nil?
            if remote_api
                @device_cache[:light_bulbs][id] = @wink_client.light_bulb id
            else 
                @device_cache[:light_bulbs][id] = @local_wink_client.light_bulb id, fetch
            end
        end

        @device_cache[:light_bulbs][id]
    end

    def clear_cache(device, opts)
        remote_api = opts.fetch :remote_api, true
        timeout = remote_api ? 6 : 2

        puts "Schedule cache removal for #{device.id}" if @debug
        @timers[device.id].cancel if !@timers[device.id].nil?
        @timers[device.id] =  @timer_group.after(timeout) {
            puts "Deleting cache for #{device.id}" if @debug
            @device_cache[:light_bulbs].delete device.id
            @timers.delete device.id
        }

        Thread.new { @timer_group.wait }
    end
end
