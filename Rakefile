@files=[]

require 'maven/ruby/maven'
require 'jar_installer'

task :default do

end

desc 'setup jar dependencies and generates <gemname>_jars.rb'
task :setup do
  Jars::JarInstaller.install_jars
end

task :install_jars do
  Jars::JarInstaller.vendor_jars
end

task :package do
  system('gem build logstash-codec-confluent.gemspec')
end


