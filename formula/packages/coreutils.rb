class Coreutils < Package

  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils"
  url "http://ftpmirror.gnu.org/coreutils/coreutils-${version}.tar.xz"

  release version: '8.29', crystax_version: 2

  depends_on 'gmp'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'libexec'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    gmp_dir = target_dep_dirs['gmp']
    openssl_dir = target_dep_dirs['openssl']

    build_env['CPPFLAGS'] = "-I#{gmp_dir}/include -I#{openssl_dir}/include"
    build_env['LDFLAGS'] += " -L#{gmp_dir}/libs/#{abi} -L#{openssl_dir}/libs/#{abi}"
    build_env['PATH']     = Build.path

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-single-binary=symlinks",
              "--disable-silent-rules",
              "--disable-rpath",
	      "--disable-nls"
            ]

    FileUtils.touch 'configure'

    system './configure', *args

    replace_lines_in_file('Makefile') do |line|
      if line == 'src_libstdbuf_so_LDFLAGS = -shared'
        'src_libstdbuf_so_LDFLAGS = -shared -Wl,-soname,libstdbuf.so'
      else
        line
      end
    end

    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded symlinks
    FileUtils.cd(install_dir) do
      files = Dir['bin/*'] - ['bin/coreutils']
      FileUtils.rm files
    end
  end
end
