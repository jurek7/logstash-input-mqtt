# encoding: utf-8
require 'logstash/inputs/base'
require 'logstash/namespace'
require 'socket'
require 'paho-mqtt'

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Mqtt < LogStash::Inputs::Base
	config_name 'mqtt'

	# If undefined, Logstash will complain, even if codec is unused.
	default :codec, 'plain'

	# https://github.com/RubyDevInc/paho.mqtt.ruby#clients-parameters
	config :host, :validate => :string, :required => true
	config :port, :validate => :number, :default => 1883
	config :topic, :validate => :string, :required => true
	config :qos, :validate => :number, :default => 0
	config :mqtt_version, :validate => :string, :default => '3.1.1'
	config :clean_session, :validate => :boolean, :default => true
	config :client_id, :validate => :string, :default => nil
	config :username, :validate => :string, :default => nil
	config :password, :validate => :string, :default => nil
	config :ssl, :validate => :boolean, :default => false
	config :will_topic, :validate => :string, :default => nil
	config :will_payload, :validate => :string, :default => ''
	config :will_qos, :validate => :string, :default => 0
	config :will_retain, :validate => :boolean, :default => false

	public
	def register
		@logstash_host = Socket.gethostname
	end # def register

	def run(queue)
		@client = PahoMqtt::Client.new({
			:host => @host,
			:port => @port,
			:persistent => true, # keep connection persistent
			:mqtt_version => @mqtt_version,
			:clean_session => @clean_session,
			:client_id => @client_id,
			:username => @username,
			:password => @password,
			:ssl => @ssl,
			:will_topic => @will_topic,
			:will_payload => @will_payload,
			:will_qos => @will_qos,
			:will_retain => @will_retain
		})
		@client.on_message do |message|
			@codec.decode(message.payload) do |event|
				host = event.get("host") || @logstash_host
				event.set("host", host)

				decorate(event)
				queue << event
			end
		end
		
		begin
			@client.connect
		rescue PahoMqtt::Exception => e
			@logger.warn("Error while setting up connection for MQTT broker! Retrying.",
				:message => e.message,
 				:class => e.class.name,
				:location => e.backtrace.first
			)
			Stud.stoppable_sleep(1) { stop? }
			retry
		end

		# subscribe to topic
		@client.subscribe([@topic, @qos])

		Stud.stoppable_sleep(1) { stop? } while !stop?
	end # def run

end # class LogStash::Inputs::Mqtt
