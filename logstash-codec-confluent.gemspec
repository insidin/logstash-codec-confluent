Gem::Specification.new do |s|

  s.name            = 'logstash-codec-confluent'
  s.version         = '0.1.0'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "Encode and decode avro formatted data for confluent.io"
  s.description     = "Encode and decode avro formatted data for confluent.io"
  s.authors         = ["Elastic"]
  s.email           = 'info@elastic.co'
  s.homepage        = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.require_paths   = ["lib"]
  s.platform        = "java"

  # Files
  #s.files = `git ls-files`.split($\)
  s.files = Dir[ 'lib/**/*.rb', 'lib/**/*.jar', 'lib/**/*.xml' ]

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "codec" }

  # Gem dependencies
  s.add_runtime_dependency 'jar-dependencies', '~> 0.1', '>= 0.1.10'
  s.add_runtime_dependency "logstash-core", '>= 1.5.0', '< 2.0.0'
  s.add_runtime_dependency "avro"  #(Apache 2.0 license)

  s.requirements << "jar 'org.apache.avro:avro', '1.7.7'"
  s.requirements << "jar 'org.apache.kafka:kafka_2.10', '0.8.2.1'"
  s.requirements << "jar 'io.confluent:kafka-avro-serializer', '1.0'"
  
  
  #s.add_runtime_dependency 'jruby-kafka', ['~> 1.4']ls -la

  #s.add_runtime_dependency 'avro-jruby'

  s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.0'
  s.add_development_dependency 'rake', '~> 10.4'
  #s.add_development_dependency 'ruby-maven-libs', '~> 3.3.0'
  #s.add_development_dependency 'ruby-maven', '=3.1.1.0.11'
  s.add_development_dependency 'ruby-maven', '~> 3.3.0'
  s.add_development_dependency 'logstash-devutils', '~> 0'





end

