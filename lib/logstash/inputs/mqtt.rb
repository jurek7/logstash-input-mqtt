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
	config :persistent, :validate => :boolean, :default => true
	config :logfile, :validate => :string, :default => '/dev/stdout'
	config :log_level, :validate => :string, :default => 'ERROR' 
	config :reconnect_limit, :validate => :number, :default => -1 #-1 infinite loop
	config :reconnect_delay, :validate => :number, :default => 5
	config :certificate_path, :validate => :string, :default => nil
	config :key_path, :validate => :string, :default => nil
	config :root_ca_path, :validate => :string, :default => nil

	public
	def register
		@logstash_host = Socket.gethostname
	end # def register

	def run(queue)
		PahoMqtt.logger = @logfile unless @logfile.nil?
		#levels: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
		PahoMqtt.logger.level = @log_level unless @logfile.nil?

		@client = PahoMqtt::Client.new({
			:host => @host,
			:port => @port,
			:persistent => @persistent, # keep connection persistent
			:mqtt_version => @mqtt_version,
			:clean_session => @clean_session,
			:client_id => @client_id,
			:username => @username,
			:password => @password,
			:ssl => @ssl,
			:will_topic => @will_topic,
			:will_payload => @will_payload,
			:will_qos => @will_qos,
			:will_retain => @will_retain,
			:reconnect_limit => @reconnect_limit,
			:reconnect_delay => @reconnect_delay,
		})

		if @ssl
			@client.config_ssl_context(@certificate_path, @key_path, @root_ca_path)
		end

		@client.on_message do |message|
			@codec.decode(message.payload) do |event|
				host = event.get("host") || @logstash_host
				event.set("host", host)
				event.set("topic", message.topic)

				decorate(event)
				queue << event
			end
		end
		
		is_connected = false

		begin
			@client.connect
			is_connected = true
		rescue PahoMqtt::Exception => e
			@logger.warn("Error while setting up connection for MQTT broker! Retrying.",
				:message => e.message,
				:class => e.class.name,
				:location => e.backtrace.first
			)
			Stud.stoppable_sleep(1) { stop? }
			retry
		end

		if is_connected
			# subscribe to topic
			@client.subscribe([@topic, @qos])

			Stud.stoppable_sleep(1) { stop? } while !stop?
		end
	end # def run

end # class LogStash::Inputs::Mqtt
