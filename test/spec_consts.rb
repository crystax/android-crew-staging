require 'pathname'

module Crew_test

  UTILS               = ['curl', 'libarchive', 'ruby']
  PORT                = 9999
  DOWNLOAD_BASE       = "http://localhost:#{PORT}"
  PKG_CACHE_BASE      = (Pathname.new(__FILE__).realpath.dirname + 'pkg.cache').to_s
  DATA_DIR            = 'data'
  CREW_DIR            = 'crew'
  NDK_DIR             = 'ndk'
  NDK_COPY_DIR        = 'ndk.copy'
  WWW_DIR             = 'www'
  DOCROOT_DIR         = File.join(WWW_DIR, 'docroot')
  DATA_READY_FILE     = '.testdataprepared'
  UTILS_RELEASES_FILE = 'data/releases_info.rb'

end
