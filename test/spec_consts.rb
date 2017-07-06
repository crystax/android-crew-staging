require 'pathname'

module Crew

  module Test

    UTILS_FILES         = ['curl', 'libarchive', 'ruby']
    UTILS_NAMES         = ['curl', 'bsdtar',     'ruby']
    TOOLS_FILES         = ['make', 'nawk', 'ndk_depends', 'ndk_stack', 'python', 'yasm']
    TOOLS_NAME          = TOOLS_FILES.map { |t| t.gsub('_', '-') }
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
end
