require "paho-mqtt"
require "logger"

module LogStash
  module Inputs
    class Mqtt
      class RecoverableMqttClient < PahoMqtt::Client
      
        attr_accessor :retry_reconnection_max_count
        attr_accessor :retry_reconnection_sleep_time
        
        def initialize(*args)
          @retry_reconnection_max_count = 3
          @retry_reconnection_sleep_time = 5
          @stop_connection = false
          super(*args)
        end
    
        def reconnect
          @reconnect_thread = Thread.new do
            retries = @retry_reconnection_max_count
            while retries != 0 do
              retries -= 1 unless retry_reconnection_max_count < 0
              if @stop
                PahoMqtt.logger.warn("RecoverableClient::Reconnection attempt is over due to stop request.") if PahoMqtt.logger?
                disconnect(false)
                exit(1)
                break
              end
              PahoMqtt.logger.debug("RecoverableClient::New reconnect attempt...remaining retries #{retries}") if PahoMqtt.logger?
              connect
              if connected?
                break
              else
                sleep @retry_reconnection_sleep_time
              end
            end
            unless connected?
              PahoMqtt.logger.error("RecoverableClient::Reconnection attempt counter is over.(#{@retry_reconnection_max_count} times)") if PahoMqtt.logger?
              disconnect(false)
              exit(1)
            end
            
          end
        end
    
        def stop
          @stop_connection = true
        end
      end #class RecoverableMqttClient
    end #class Mqtt
  end #module Inputs
end #module LogStash