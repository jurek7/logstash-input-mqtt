Gem::Specification.new do |s|
  s.name          = 'logstash-input-paho-mqtt'
  s.version       = '0.1.2'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Logstash MQTT input plugin.'
  s.homepage      = 'https://github.com/jurek7/logstash-input-mqtt'
  s.authors       = ['juri']
  s.email         = 'jurkiewiczmichal@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'paho-mqtt', '>= 1.0.5'
  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
end
