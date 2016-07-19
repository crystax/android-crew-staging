class Gcc < Part

  desc "GCC-based toolchain"
  homepage "https://gcc.gnu.org"
  url "toolchain/gcc"

  release version: '4.9', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  release version: '5', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                      darwin_x86_64:  '0',
                                                      windows_x86_64: '0',
                                                      windows:        '0'
                                                    }

  release version: '6', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                      darwin_x86_64:  '0',
                                                      windows_x86_64: '0',
                                                      windows:        '0'
                                                    }


  #  ~/src/ndk/platform/ndk/build/instruments/build-gcc.sh
  #     ~/src/ndk/toolchain /ssd/src/ndk/platform/ndk arm-linux-androideabi-4.9
  #     --try-64
  #     --package-dir=/tmp/ndk-zuav/tmp/build-13950/release-10.3.1-20160510/prebuilt
  #     --with-python=prebuilt
  #     -j16
  def build_for_platform_and_abi(platform, abi, release, options, dep_dirs)
    #install_dir = install_dir_for_platform_and_abi(platform, abi, release)

    # host ppl
    #

    # build target binutils

    # build gcc

    # build gdb
  end
end
