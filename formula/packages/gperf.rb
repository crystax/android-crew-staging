class Gperf < Package

  name 'gperf'
  desc "GNU gperf is a perfect hash function generator"
  homepage "https://www.gnu.org/software/gperf/"
  url "http://ftp.gnu.org/pub/gnu/gperf/gperf-${version}.tar.gz"

  release '3.1', crystax: 3

  build_copy 'COPYING'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}"
            ]

    build_env['CXXFLAGS'] += ' -lgnustl_shared'

    configure *args
    make
    make 'install'
  end
end
