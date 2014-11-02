require "wink"
require "faraday"
require "faraday_middleware"

module Wink
    module Devices
        class LocalLightBulb < LightBulb
            def initialize(client, device)
                super
            end

            def on
                device["last_reading"]["powered"] = true
                client.request :post, { :m => device_id, :t => 1, :v => "ON" }
            end

            def off
                device["last_reading"]["powered"] = false
                client.request :post, { :m => device_id, :t => 1, :v => "OFF" }
            end

            def dim(scale)
                device["last_reading"]["brightness"] = scale
                brightness = (255.0 * scale).round()
                client.request :post, { :m => device_id, :t => 2, :v => brightness }
            end
        end
    end

    class LocalClient
        def light_bulb(id, fetch = false) 
            device = { "light_bulb_id" => id, "last_reading" => {} }

            if fetch
                response = request :get, { :m => id }
                response.body.each do |key, value|
                    case key
                    when "1"
                        device["last_reading"]["powered"] = value == "ON"     
                    when "2"
                        device["last_reading"]["brightness"] = (value.to_i / 255.0).round 2
                    end
                end
            end
            
            Devices::LocalLightBulb.new(self, device)
        end

        def request(method, params = {})
            connection = Faraday.new("http://10.0.1.205/local_api/")
            connection.response :json, :content_type => /\bjson$/

            case method
            when :post
                connection.post "index.php", params
            when :get
                connection.get "index.php", params
            end
        end
    end
end
