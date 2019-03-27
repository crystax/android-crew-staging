class Cpulimit < Package

  desc "Cpulimit is a tool which limits the CPU usage of a process"
  homepage "https://github.com/opsengine/cpulimit"
  url "https://github.com/opsengine/cpulimit/archive/v${version}.tar.gz"

  release '0.2', crystax: 4

  build_copy 'LICENSE'
  build_options build_outside_source_tree: false,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false


  def build_for_abi(abi, _toolchain,  _release, _options)
    system 'make', '-j', num_jobs

    bin_dir = "#{install_dir_for_abi(abi)}/bin"
    FileUtils.mkdir_p bin_dir
    FileUtils.cp 'src/cpulimit', bin_dir
  end
end
