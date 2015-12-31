class Boost < Library

  desc "Boost libraries built without ICU4C"
  homepage "http://www.boost.org"
  url "https://downloads.sourceforge.net/project/boost/boost/${version}/boost_${block}.tar.bz2" do |v| v.gsub('.', '_') end

  release version: '1.60.0', crystax_version: 1, sha256: '0'

  build_options setup_env: false,
                wrapper_replace: { '-dynamiclib'    => '-shared',
                                   '-undefined'     => '-u',
                                   '-m32'           => '',
                                   '-m64'           => '',
                                   '-single_module' => '',
                                   '-lpthread'      => '',
                                   '-lutil'         => ''
                                 },
                pack_libs: :copy_lib_dir


  def build_for_abi(abi, toolchain, release, _dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    arch = Build.arch_for_abi(abi)
    bjam_arch, bjam_abi = bjam_data(arch)

    common_args = [ "-d+2",
                    "-q",
                    "-j1",                   ##{num_jobs}",
                    "variant=release",
                    "link=static,shared",
                    "runtime-link=shared",
                    "threading=multi",
                    "target-os=android",
                    "binary-format=elf",
                    "address-model=#{arch.num_bits}",
                    "architecture=#{bjam_arch}",
                    "abi=#{bjam_abi}",
                    "--user-config=user-config.jam",
                    "--layout=system",
                    without_libs(release, arch).map { |lib| "--without-#{lib}" },
             "install"
           ].flatten

    #stls = Build.cxx_std_libs.map { |l| Build.toolchain_for_cxx_std_lib(l) }

    [Build::DEFAULT_TOOLCHAIN].each do |toolchain|
      stl_name = toolchain.stl_name
      puts "    using C++ standard library: #{stl_name}"
      # todo: copy sources for every toolchain
      src_dir = build_dir_for_abi(abi)
      work_dir = "#{src_dir}/#{stl_name}"
      host_tc_dir = "#{work_dir}/host-bin"
      FileUtils.mkdir_p host_tc_dir
      host_cc = "#{host_tc_dir}/cc"
      Build.gen_host_compiler_wrapper host_cc, 'gcc'

      build_env['PATH'] = "#{work_dir}:#{ENV['PATH']}"
      system './bootstrap.sh',  "--with-toolset=cc"

      gen_project_config_jam src_dir, arch, abi, stl_name
      gen_user_config_jam    src_dir

      build_env.clear
      cxx = "#{build_dir_for_abi(abi)}/#{toolchain.cxx_compiler_name}"
      cxxflags = Build.cflags(abi) + ' ' + Build.sysroot(abi) + ' ' + toolchain.search_path_for_stl_includes(abi) + ' -fPIC -Wno-long-long'
      ldflags  = Build.ldflags(abi) + ' ' + toolchain.search_path_for_stl_libs(abi)

      Build.gen_compiler_wrapper cxx, toolchain.cxx_compiler(arch), toolchain, build_options, cxxflags, ldflags
      #['as', 'ar', 'ranlib', 'strip'].each { |tool| Build.gen_tool_wrapper build_dir_for_abi(abi), tool, toolchain, arch }

      build_env['PATH'] = "#{src_dir}:#{ENV['PATH']}"

      build_dir = "#{work_dir}/build"
      prefix_dir = "#{work_dir}/install"
      args = common_args + ["--prefix=#{prefix_dir}", "--build-dir=#{build_dir}"]

      system './b2', *args
      # todo: copy libs to
    end

    # todo: copy headers
    # install_dir_for_abi(abi)
  end

  def bjam_data(arch)
    case arch.name
    when /^arm/               # arm|arm64
      bjam_arch = 'arm'
      bjam_abi = 'aapcs'
    when /^x86/               # x86|x86_64
      bjam_arch = 'x86'
      bjam_abi  = 'sysv'
    when 'mips'
      bjam_arch = 'mips1'
      bjam_abi  = 'o32'
    when 'mips64'
      bjam_arch = 'mips1'
      bjam_abi  = 'o64'
    else
      raise UnsupportedArch.new(arch)
    end

    [bjam_arch, bjam_abi]
  end

  def without_libs(release, arch)
    exclude = []
    major, minor, _ = release.version.split('.')

    # Boost.Context in 1.60.0 and earlier don't support mips64
    if major.to_i == 1 and minor.to_i <= 60
      exclude << 'context'
    end

    # Boost.Coroutine depends on Boost.Context
    if exclude.include? 'context'
      exclude << 'coroutine'
      # Starting from 1.59.0, there is Boost.Coroutine2 library, which depends on Boost.Context too
      if major.to_i == 1 and minor.to_i >= 59
        exclude << 'coroutine2'
      end
    end

    exclude
  end

  def gen_project_config_jam(dir, arch, abi, stl_name)
    # todo: handle python
    python_version = '3.5'
    python_dir = "#{Global::NDK_DIR}/sources/python/#{python_version}"

    filename = "#{dir}/project-config.jam"
    File.open(filename, 'w') do |f|
      f.puts "import option ;"
      f.puts "import feature ;"
      f.puts "import python ;"
      f.puts "using python : #{python_version} : #{python_dir} : #{python_dir}/include/python : #{python_dir}/libs/#{abi} ;"
      case stl_name
      when /^gnu-/
        f.puts "using gcc : #{arch.name} : g++ ;"
        f.puts "project : default-build <toolset>gcc ;"
      when /^llvm-/
        f.puts "using clang : #{arch.name} : clang++ ;"
        f.puts "project : default-build <toolset>clang ;"
      else
        raise "unsupported C++ standard library: #{stl_name}"
      end
      f.puts "libraries = ;"
      f.puts "option.set keep-going : false ;"
    end
  end

  def gen_user_config_jam(dir)
    filename = "#{dir}/user-config.jam"
    File.open(filename, 'w') { |f| f.puts "using mpi ;" }
  end
end
