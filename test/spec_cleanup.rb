require 'fileutils'
require_relative 'spec_consts.rb'


FileUtils.rm_rf 'tmp'
FileUtils.rm_rf Crew::Test::NDK_DIR
FileUtils.rm_rf Crew::Test::NDK_COPY_DIR
FileUtils.rm_rf Crew::Test::PKG_CACHE_DIR
FileUtils.rm_rf Crew::Test::WWW_DIR

FileUtils.cd(Crew::Test::DATA_DIR) { FileUtils.rm Dir['curl-*.rb', 'libarchive-*.rb', 'ruby-*.rb', 'xz-*.rb', 'releases_info.rb'] }
FileUtils.rm_f Crew::Test::DATA_READY_FILE
