class Flex < Package

  desc "Flex is a fast lexical analyser generator"
  homepage "https://www.gnu.org/software/flex/"
  url "https://github.com/westes/flex/files/981163/flex-${version}.tar.gz"

  release '2.6.4', crystax: 2

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'include', 'lib'],
                gen_android_mk:      false


  def pre_build(src_dir, _release)
    base_dir = build_base_dir
    build_dir = "#{build_base_dir}/native"
    FileUtils.mkdir_p build_dir

    Build.gen_host_compiler_wrapper "#{build_dir}/gcc", 'gcc'
    Build.gen_host_compiler_wrapper "#{build_dir}/g++", 'g++'

    build_env['PATH'] = "#{build_dir}:#{ENV['PATH']}"

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure"
      system 'make', '-j', num_jobs
    end

    build_dir
  end

  def build_for_abi(abi, toolchain,  _release, _options)
    args = [ '--disable-silent-rules',
             '--disable-rpath',
             '--disable-nls',
             '--with-pic',
             '--with-sysroot'
           ]

    configure *args

    FileUtils.cp "#{pre_build_result}/src/stage1flex", 'src/stage1flex'
    FileUtils.touch 'src/stage1flex', mtime: Time.now + 3600

    make
    make 'install'

    clean_install_dir abi
  end
end
