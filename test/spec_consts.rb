require 'pathname'

module Crew

  module Test

    FormulaData = Struct.new(:type, :filename, :name) do
      def initialize(type, filename, name = nil)
        name ||= filename.gsub('_', '-')
        super type, filename, name
      end
    end

    # here utilities must be sorted by their filenames
    ALL_TOOLS           = [FormulaData.new(:build_dependency, 'cloog'),
                           FormulaData.new(:build_dependency, 'cloog_old'),
                           FormulaData.new(:tool,             'curl'),
                           FormulaData.new(:build_dependency, 'expat'),
                           FormulaData.new(:tool,             'gcc'),
                           FormulaData.new(:build_dependency, 'gmp'),
                           FormulaData.new(:build_dependency, 'isl'),
                           FormulaData.new(:build_dependency, 'isl_old'),
                           FormulaData.new(:tool,             'libarchive', 'bsdtar'),
                           FormulaData.new(:build_dependency, 'libedit'),
                           FormulaData.new(:build_dependency, 'libgit2'),
                           FormulaData.new(:build_dependency, 'libssh2'),
                           FormulaData.new(:tool,             'llvm'),
                           FormulaData.new(:tool,             'make'),
                           FormulaData.new(:build_dependency, 'mpc'),
                           FormulaData.new(:build_dependency, 'mpfr'),
                           FormulaData.new(:tool,             'nawk'),
                           FormulaData.new(:tool,             'ndk_base'),
                           FormulaData.new(:tool,             'ndk_depends'),
                           FormulaData.new(:tool,             'ndk_stack'),
                           FormulaData.new(:build_dependency, 'openssl'),
                           FormulaData.new(:build_dependency, 'ppl'),
                           FormulaData.new(:tool,             'python'),
                           FormulaData.new(:tool,             'ruby'),
                           FormulaData.new(:build_dependency, 'xz'),
                           FormulaData.new(:tool,             'yasm'),
                           FormulaData.new(:build_dependency, 'zlib')
                          ]
    UTILS_FILES         = ['curl', 'libarchive', 'ruby']
    PORT                = 9999
    DOWNLOAD_BASE       = "http://localhost:#{PORT}"
    SRC_CACHE_DIR       = 'src.cache'
    PKG_CACHE_DIR       = 'pkg.cache'
    DATA_DIR            = 'data'
    CREW_DIR            = 'crew'
    NDK_DIR             = 'ndk'
    NDK_COPY_DIR        = 'ndk.copy'
    WWW_DIR             = 'www'
    DOCROOT_DIR         = WWW_DIR
    DATA_READY_FILE     = '.testdataprepared'
    UTILS_RELEASES_FILE = 'data/releases_info.rb'
  end
end
