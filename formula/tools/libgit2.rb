class Libgit2 < BuildDependency

  desc "A portable, pure C implementation of the Git core methods provided as a re-entrant linkable library with a solid API"
  homepage 'https://libgit2.github.com/'
  url 'https://github.com/libgit2/libgit2/archive/v${version}.tar.gz'

  release version: '0.24.2', crystax_version: 1, sha256: { linux_x86_64:   '016d5d27b1c053c77e6a3e0b232d3566b3c4566b822bc987f876a4d8d320170c',
                                                           darwin_x86_64:  '8acf90127948cfe2d1705d3754c4526b3667cc5cee670b32759aa7f0254df46c',
                                                           windows_x86_64: '631d40074f3257468b1cfd4840b9c87418405b8700c53f63234f35d1d206c5a0',
                                                           windows:        '99884c2697707b5f77d3b3aa5e2a0b8a3db4050e0c6d14f6273e1219e6a3359e'
                                                         }

  depends_on 'zlib'
  depends_on 'openssl'
  depends_on 'libssh2'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = host_dep_dirs[platform.name]['zlib']
    openssl_dir = host_dep_dirs[platform.name]['openssl']
    libssh2_dir = host_dep_dirs[platform.name]['libssh2']

    FileUtils.cp_r File.join(src_dir, '.'), '.'

    build_env['EXTRA_CFLAGS']   = "#{platform.cflags}"
    build_env['EXTRA_DEFINES']  = "-DGIT_OPENSSL -DOPENSSL_SHA1 -DGIT_SSH -DGIT_THREADS"
    build_env['EXTRA_INCLUDES'] = "-I#{zlib_dir}/include -I#{openssl_dir}/include -I#{libssh2_dir}/include"

    build_env['EXTRA_DEFINES'] += " -DGIT_ARCH_64"  unless platform.name == 'windows'
    build_env['EXTRA_DEFINES'] += " -DGIT_USE_NSEC" if platform.target_os == 'windows'

    make_args = ['-f', 'Makefile.crystax']

    if platform.target_os == 'windows'
      build_env['EXTRA_DEFINES'] += " -DGIT_WIN32"
      make_args << 'MINGW=1'
    end

    system 'make', *make_args

    FileUtils.mkdir_p ["#{install_dir}/lib", "#{install_dir}/include"]
    #
    FileUtils.cp   './libgit2.a',      "#{install_dir}/lib/"
    FileUtils.cp   './include/git2.h', "#{install_dir}/include/"
    FileUtils.cp_r './include/git2',   "#{install_dir}/include/"
  end
end
