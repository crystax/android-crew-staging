class Llvm < Tool

  desc "LLVM-based toolchain"
  homepage "https://gcc.gnu.org"
  url "toolchain/llvm-${major_version}.${minor_version}"

  release version: '3.7', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  release version: '3.8', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  def build_for_platform_and_abi(platform, abi, release, options, dep_dirs)
    #install_dir = install_dir_for_platform(platform, release)
  end
end
