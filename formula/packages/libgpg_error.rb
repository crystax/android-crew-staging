class LibgpgError < Package

  name 'libgpg-error'
  desc "Libgpg-error is a small library that originally defined common error values for all GnuPG components"
  homepage "https://www.gnupg.org/software/libgpg-error/"
  url "https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${version}.tar.bz2"

  release '1.35'

  build_copy 'COPYING','COPYING.LIB'
  build_libs 'libgpg-error'
  build_options build_outside_source_tree: false

  def build_for_abi(abi, _toolchain,  _release, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--disable-silent-rules",
              "--enable-threads",
              "--enable-shared",
              "--enable-static",
              "--disable-nls",
              "--disable-rpath",
              "--disable-languages",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args

    set_pthread_in_use_detection_hard 'config.h'
    FileUtils.cd('src/syscfg') do
      # see also: https://github.com/termux/termux-packages/tree/master/packages/libgpg-error
      case Build.arch_for_abi(abi).name
      when 'x86'
        FileUtils.cp 'lock-obj-pub.arm-unknown-linux-androideabi.h', 'lock-obj-pub.linux-android.h'
      when 'x86_64'
        FileUtils.cp 'lock-obj-pub.aarch64-unknown-linux-android.h', 'lock-obj-pub.linux-android.h'
      when 'mips'
        # todo: generate on device
        FileUtils.cp 'lock-obj-pub.mipsel-unknown-linux-gnu.h', 'lock-obj-pub.linux-android.h'
      when 'mips64'
        # todo: generate on device
        FileUtils.cp 'lock-obj-pub.mips64el-unknown-linux-gnuabi64.h', 'lock-obj-pub.linux-android.h'
      end
    end

    make
    make 'install'

    clean_install_dir abi
  end
end
