class Gmp < Package

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release '6.1.2'

  build_options use_cxx:              true,
                ldflags_in_c_wrapper: true
  build_copy 'COPYING', 'COPYING.LESSERv3', 'COPYINGv2', 'COPYINGv3'
  build_libs 'libgmp', 'libgmpxx'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-cxx",
              "--enable-shared",
              "--enable-static",
              "--with-pic"
            ]
    args << "--disable-assembly" if abi == 'mips64'

    build_env['CXXFLAGS'] += ' -lgnustl_shared'

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.cd(install_dir) do
      FileUtils.rm Dir['lib/*.la']
      FileUtils.rm_rf 'share'
    end
  end
end
