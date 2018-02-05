class Libunistring < Package

  desc "This library provides functions for manipulating Unicode strings and for manipulating C strings according to the Unicode standard"
  homepage "https://www.gnu.org/software/libunistring/"
  url "http://ftp.gnu.org/gnu/libunistring/libunistring-0.9.8.tar.xz"

  release version: '0.9.8', crystax_version: 1

  build_copy 'COPYING', 'COPYING.LIB'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--with-pic",
              "--enable-shared",
              "--enable-static",
              "--with-sysroot"
            ]

    system './configure', *args
    # libunistring uses pthread_cancel to check whether pthread is in use
    # since we do not have pthread_cancel (at least right now) we must handle the issue by editing config.h
    Build.replace_lines_in_file('config.h') do |line|
      if line == '/* #undef PTHREAD_IN_USE_DETECTION_HARD */'
        '#define PTHREAD_IN_USE_DETECTION_HARD 1'
      else
        line
      end
    end

    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.cd(install_dir) do
      FileUtils.rm Dir["lib/*.la"]
      FileUtils.rm_rf 'share'
    end
  end
end
