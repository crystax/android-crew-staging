require 'fileutils'
require 'rspec'
require 'socket'
require 'webrick'
require 'pathname'
require_relative 'spec_consts.rb'


log_dir = File.join(Crew::Test::WWW_DIR, 'log')
base_dir = 'crew'

FileUtils.mkdir(log_dir) unless Dir.exist?(log_dir)

server = WEBrick::HTTPServer.new :Port => Crew::Test::PORT,
                                 :DocumentRoot => Crew::Test::DOCROOT_DIR,
                                 :Logger => WEBrick::Log.new(File.join(log_dir, 'webrick.log')),
                                 :AccessLog => [[File.open(File.join(log_dir, 'access.log'),'w'),
                                                 WEBrick::AccessLog::COMBINED_LOG_FORMAT]]

Thread.start { server.start }

FileUtils.rm_rf Crew::Test::CREW_DIR

FileUtils.mkdir_p File.join(Crew::Test::NDK_DIR, 'sources')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'formula')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'patches')

ENV['CREW_DOWNLOAD_BASE'] = Crew::Test::DOWNLOAD_BASE
ENV['CREW_BASE_DIR']      = "#{File.dirname(__FILE__)}/#{Crew::Test::CREW_DIR}"
ENV['CREW_NDK_DIR']       = "#{File.dirname(__FILE__)}/#{Crew::Test::NDK_DIR}"
ENV['CREW_PKG_CACHE_DIR'] = "#{File.dirname(__FILE__)}/#{Crew::Test::PKG_CACHE_DIR}"
ENV['CREW_SRC_CACHE_DIR'] = "#{File.dirname(__FILE__)}/#{Crew::Test::SRC_CACHE_DIR}"

# global.rb requires evn vars to be set so we put it here
require_relative '../library/global.rb'

# helpers.rb uses constants from 'global.rb'
require_relative 'helpers.rb'


require 'rspec/expectations'
RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 200000

RSpec.configure do |config|
  config.include Spec::Helpers
end
