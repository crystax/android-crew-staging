require 'pathname'

module Crew

  module Test

    FormulaData = Struct.new(:filename, :name) do
      def initialize(filename, name = nil)
        name ||= filename.gsub('_', '-')
        super filename, name
      end
    end

    UTILS_FILES         = ['curl', 'libarchive', 'ruby']
    TOOLS_FILES         = ['make', 'nawk', 'ndk_depends', 'ndk_stack', 'python', 'yasm']
    # here tools must be sorted by their filenames
    ALL_TOOLS           = [FormulaData.new('curl'),
                           FormulaData.new('libarchive', 'bsdtar'),
                           FormulaData.new('make'),
                           FormulaData.new('nawk'),
                           FormulaData.new('ndk_depends'),
                           FormulaData.new('ndk_stack'),
                           FormulaData.new('python'),
                           FormulaData.new('ruby'),
                           FormulaData.new('yasm')
                          ]
    PORT                = 9999
    DOWNLOAD_BASE       = "http://localhost:#{PORT}"
    PKG_CACHE_BASE      = 'pkg.cache'
    DATA_DIR            = 'data'
    CREW_DIR            = 'crew'
    NDK_DIR             = 'ndk'
    NDK_COPY_DIR        = 'ndk.copy'
    WWW_DIR             = 'www'
    DOCROOT_DIR         = "#{WWW_DIR}/crew-pkg-cache-#{ENV['USER']}"
    DATA_READY_FILE     = '.testdataprepared'
    UTILS_RELEASES_FILE = 'data/releases_info.rb'
  end
end
