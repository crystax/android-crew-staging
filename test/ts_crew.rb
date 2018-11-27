require 'fileutils'
require_relative 'spec_consts.rb'

# create require directories
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'cache')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'etc')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'patches')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'formula', 'packages')
FileUtils.mkdir_p File.join(Crew::Test::CREW_DIR, 'formula', 'tools')
FileUtils.mkdir_p File.join(Crew::Test::NDK_DIR, 'sources')
FileUtils.mkdir_p File.join(Crew::Test::NDK_DIR, 'packages')


require 'minitest/autorun'

require_relative 'test_arch.rb'
require_relative 'test_crew.rb'
require_relative 'test_exceptions.rb'
require_relative 'test_formula.rb'
require_relative 'test_release.rb'
require_relative 'test_utils.rb'
require_relative 'test_command_options.rb'
require_relative 'test_build_options.rb'
require_relative 'test_cleanup_options.rb'
require_relative 'test_info_options.rb'
require_relative 'test_install_options.rb'
require_relative 'test_list_options.rb'
require_relative 'test_make_deb_options.rb'
require_relative 'test_make_posix_env_options.rb'
require_relative 'test_shasum_options.rb'
require_relative 'test_source_options.rb'
# todo: fails to run because name conflict between Minitest::Test and Crew::Test
#require_relative 'test_test_options.rb'


# cleanup
FileUtils.rm_rf [Crew::Test::CREW_DIR, Crew::Test::NDK_DIR]
