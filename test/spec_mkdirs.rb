require 'fileutils'
require_relative 'spec_consts.rb'


FileUtils.mkdir_p File.join(Crew_test::CREW_DIR, 'cache')
FileUtils.mkdir_p File.join(Crew_test::CREW_DIR, 'patches')
FileUtils.mkdir_p File.join(Crew_test::CREW_DIR, 'formula', 'packages')
FileUtils.mkdir_p File.join(Crew_test::CREW_DIR, 'formula', 'tools')

FileUtils.mkdir_p File.join(Crew_test::NDK_DIR, 'sources')
FileUtils.mkdir_p File.join(Crew_test::NDK_DIR, 'packages')
