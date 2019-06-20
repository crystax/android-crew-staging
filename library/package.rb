require 'fileutils'
require_relative 'release.rb'
require_relative 'build.rb'
require_relative 'deb.rb'
require_relative 'target_base.rb'
require_relative 'properties.rb'


class Package < TargetBase

  SRC_DIR_BASENAME  = 'src'
  TEST_DIR_BASENAME = 'tests'

  DEF_BUILD_OPTIONS = { source_archive_without_top_dir: false,
                        build_outside_source_tree:      true,
                        need_git_data:                  false,
                        support_pkgconfig:              true,
                        add_deps_to_cflags:             true,
                        add_deps_to_ldflags:            true,
                        c_wrapper:                      'cc',
                        sysroot_in_cflags:              true,
                        cflags_in_c_wrapper:            false,
                        ldflags_in_c_wrapper:           false,
                        ldflags_no_pie:                 false,
                        use_cxx:                        false,
                        cxx_wrapper:                    'c++',
                        setup_env:                      true,
                        use_standalone_toolchain:       false,
                        use_static_libcrystax:          false,
                        copy_installed_dirs:            ['lib', 'include'],
                        check_sonames:                  true,
                        gen_android_mk:                 true,
                        wrapper_translate_sonames:      Hash.new,
                        wrapper_fix_stl:                false,
                        wrapper_remove_args:            Array.new,
                        wrapper_replace_args:           Hash.new
                      }.freeze

  attr_reader :pre_build_result, :post_build_result

  def has_home_directory?
    true
  end

  def home_directory
    File.join(Global::HOLD_DIR, file_name)
  end

  def release_directory(release, _platform_name = nil)
    File.join(home_directory, release.version)
  end

  def properties_directory(release, platform_name = nil)
    release_directory release, platform_name
  end

  def install_archive(release, archive, _platform_name = nil)
    rel_dir = release_directory(release)
    prop = get_properties(rel_dir)

    FileUtils.rm_rf binary_files(rel_dir)
    Utils.unpack archive, rel_dir

    update_pc_files release
    # todo:
    #update_root_android_mk release

    prop.merge! get_properties(rel_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def uninstall(release)
    puts "removing #{name}:#{release.version}"
    rel_dir = release_directory(release)
    if not release.source_installed?
      FileUtils.rm_rf rel_dir
    else
      prop = get_properties(rel_dir)
      FileUtils.rm_rf binary_files(rel_dir)
      prop[:installed] = false
      prop.delete :build_info
      save_properties prop, rel_dir
    end
    release.installed = false
  end

  def source_installed?(release = Release.new)
    releases.any? { |r| r.match?(release) and r.source_installed? }
  end

  def install_source(release)
    puts "installing source code for #{name}:#{release}"
    rel_dir = release_directory(release)
    prop = get_properties(rel_dir)

    if prop[:installed_crystax_version] == nil
      prop[:installed_crystax_version] = release.crystax_version
      FileUtils.mkdir_p rel_dir
    end

    prepare_source_code release, rel_dir, SRC_DIR_BASENAME, '='

    release.source_installed = release.crystax_version
    prop[:source_installed] = true

    save_properties prop, rel_dir
  end

  def uninstall_source(release)
    puts "uninstalling source code for #{name}:#{release.version}"
    rel_dir = release_directory(release)
    if not release.installed?
      FileUtils.rm_rf rel_dir
    else
      prop = get_properties(rel_dir)
      FileUtils.rm_r source_directory(release)
      prop[:source_installed] = false
      save_properties prop, rel_dir
    end
    release.source_installed = false
  end

  def build(release, options, host_dep_info, target_dep_info)
    base_dir = build_base_dir
    FileUtils.rm_rf base_dir
    FileUtils.mkdir_p base_dir

    @log_file = build_log_file
    @build_release = release

    parse_host_dep_info   host_dep_info
    parse_target_dep_info target_dep_info

    arch_list = Build.abis_to_arch_list(options.abis)
    build_log_puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(', ')}"
    unless options.package_options[self.name].lines.empty?
      build_log_puts "Using package build options:"
      options.package_options[self.name].lines.each { |pbo| build_log_puts "  #{pbo}" }
    end

    src_dir = source_directory(release)
    @num_jobs = options.num_jobs

    build_env.clear
    raise "static libcrystax can be used only with standalone toolchain" if build_options[:use_static_libcrystax] and not build_options[:use_standalone_toolchain]

    if self.respond_to? :pre_build
      build_log_print "= executing pre build step: "
      @pre_build_result = pre_build(src_dir, release)
      build_log_puts @pre_build_result ? @pre_build_result : 'OK'
    end

    toolchain = Build::DEFAULT_TOOLCHAIN
    build_options[:wrapper_translate_sonames] = sonames_translation_table(release) if self.respond_to? :sonames_translation_table

    FileUtils.mkdir_p package_dir
    arch_list.each do |arch|
      build_log_puts "= building for architecture: #{arch.name}"
      if build_options[:use_standalone_toolchain]
        warning "build option 'cflags_in_c_wrapper=true' ignored for standalone toolchains" if build_options[:cflags_in_c_wrapper]
        st_packages = @target_dep_dirs.keys
        st_base_dir = "#{build_base_dir}/#{arch.name}-toolchain"
        build_log_puts "  making standalone toolchain with packages: #{st_packages}"
        toolchain = Toolchain::Standalone.new(arch, st_base_dir, Toolchain::DEFAULT_GCC, Toolchain::DEFAULT_LLVM, st_packages, self)
        if build_options[:use_static_libcrystax]
          toolchain.remove_dynamic_libcrystax
        else
          toolchain.remove_static_libcrystax
        end
      end
      arch.abis_to_build.each do |abi|
        build_log_puts "  building for abi: #{abi}"
        FileUtils.mkdir_p base_dir_for_abi(abi)
        build_dir = build_dir_for_abi(abi)
        #
        if build_options[:build_outside_source_tree]
          FileUtils.mkdir_p build_dir
        else
          FileUtils.cp_r "#{src_dir}/.", build_dir
          # without this code some packages (f.e. cpio) could fail to build
          timestamp = Time.new.localtime.strftime('%Y%m%d%H%M.%S')
          Dir["#{build_dir}/**/*"].each { |f| Utils::run_command('touch', '-t', timestamp, f) }
        end
        #
        setup_build_env abi, toolchain if build_options[:setup_env]
        @build_abi = abi
        FileUtils.cd(build_dir) { build_for_abi abi, toolchain, release, options }
        install_dir = install_dir_for_abi(abi)
        Dir["#{install_dir}/**/*.pc"].each { |file| pc_edit_file file, release, abi unless File.symlink? file }
        Build.check_sonames install_dir, arch if build_options[:check_sonames]
        copy_installed_files abi
        FileUtils.rm_rf base_dir_for_abi(abi) unless options.no_clean?
      end
    end

    Build.gen_android_mk "#{package_dir}/Android.mk", build_libs, build_options if build_options[:gen_android_mk]

    if self.respond_to? :post_build
      build_log_print "= executing post build step: "
      @post_build_result = post_build(package_dir, release)
      build_log_puts @post_build_result ? @post_build_result : 'OK'
    end

    build_copy.each { |f| FileUtils.cp "#{src_dir}/#{f}", package_dir }
    copy_tests release

    write_build_info package_dir

    if options.build_only?
      build_log_puts "Build only, no packaging and installing"
    else
      archive = cache_file(release)
      build_log_puts "Creating archive file #{archive}"
      Utils.pack(archive, package_dir)
      # remove old deb file to force make-posix-env command to make new one
      clean_deb_cache release, options.abis

      update_shasum release if options.update_shasum?

      # install into packages (and update props if any)
      # we do not use Formula's install method here to bypass SHA256 sum checks,
      # build command is intended for a developers
      if options.install?
        build_log_puts "Unpacking archive into #{release_directory(release)}"
        install_archive release, archive
      end
    end

    if options.no_clean?
      build_log_puts "No cleanup, for build artifacts see #{base_dir}"
    else
      FileUtils.rm_rf base_dir
    end
  end

  def support_testing?
    true
  end

  def test(release, options)
    base_dir = test_base_dir
    puts "removing directory: #{base_dir}"
    FileUtils.rm_rf base_dir
    FileUtils.mkdir_p base_dir
    @log_file = test_log_file

    arch_list = Build.abis_to_arch_list(options.abis)
    test_log_puts "Testing #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"

    @num_jobs = options.num_jobs

    arch_list.each do |arch|
      test_log_puts "= testing for architecture: #{arch.name}"

      arch.abis_to_build.each do |abi|
        test_log_puts "  building for abi: #{abi}"

        options.toolchains.each do |toolchain|
          test_log_puts "    using toolchain: #{toolchain}"

          test_dir = test_dir_for(abi, toolchain)
          FileUtils.mkdir_p test_dir
          Dir["#{test_directory(release)}/*"].each do |test|
            test_name = File.basename(test)
            raise "not directory in test directory: #{test}" unless File.directory?(test)
            test_log_puts "      #{test_name}"
            FileUtils.cp_r test, test_dir
            build_test "#{test_dir}/#{test_name}", abi, toolchain
          end
        end
      end
    end
  end

  def build_test(test_dir, abi, toolchain)
    ndk_build '-C', test_dir, 'V=1', "APP_ABI=#{abi}", "NDK_TOOLCHAIN_VERSION=#{toolchain.gsub(/gcc/, '')}"
  end

  def source_directory(release)
    "#{release_directory(release)}/#{SRC_DIR_BASENAME}"
  end

  def test_directory(release)
    "#{release_directory(release)}/#{TEST_DIR_BASENAME}"
  end

  def setup_build_env(abi, toolchain)
    arch = Build.arch_for_abi(abi)
    @build_env = {}

    if toolchain.standalone?
      lib = (abi == 'mips64') ? 'lib64' : 'lib'
      cflags  = toolchain.gcc_cflags(abi) + " --sysroot=#{toolchain.sysroot_dir}"   # -I#{toolchain.sysroot_dir}/usr/include"
      ldflags = toolchain.gcc_ldflags(abi) + " --sysroot=#{toolchain.sysroot_dir}"  # -L#{toolchain.sysroot_dir}/usr/#{lib}"
      cc = toolchain.gcc
      @build_env['PKG_CONFIG_PATH'] = nil
      @build_env['PKG_CONFIG_SYSROOT_DIR'] = nil
      @build_env['PKG_CONFIG_LIBDIR'] = toolchain.pkgconfig_dir
    else
      cflags  = toolchain.cflags(abi)
      ldflags = toolchain.ldflags(abi)

      if build_options[:support_pkgconfig]
        pc_deps_a, deps_a = @target_dep_dirs.partition { |dn, _| Dir.exist? "#{target_dep_pkgconfig_dir(dn, abi)}" }
        pc_deps = pc_deps_a.to_h
        deps = deps_a.to_h
      else
        pc_deps = {}
        deps = @target_dep_dirs
      end

      #debug
      # puts "deps:          #{deps}"
      # puts "pc deps:       #{pc_deps}"
      # puts "pc_deps.empty: #{pc_deps.empty?}"
      # exit

      unless pc_deps.empty?
        @build_env['PKG_CONFIG_DIR'] = nil
        @build_env['PKG_CONFIG_SYSROOT_DIR'] = nil
        @build_env['PKG_CONFIG_LIBDIR'] = pc_deps.keys.map { |n| target_dep_pkgconfig_dir(n, abi) }.join(':')
        # @build_env['PKG_CONFIG_PATH'] = @build_env['PKG_CONFIG_LIBDIR']
      end

      if build_options[:add_deps_to_cflags]
        cflags += ' ' + deps.keys.map { |n| "-I#{target_dep_include_dir(n)}" }.join(' ')
      end

      if build_options[:add_deps_to_ldflags]
        ldflags += ' ' + deps.keys.map { |n| "-L#{target_dep_lib_dir(n, abi)}" }.join(' ')
      end

      c_comp = toolchain.c_compiler(arch, abi)

      if build_options[:sysroot_in_cflags]
        cflags += " --sysroot=#{Build.sysroot(abi)}"
      else
        c_comp += " --sysroot=#{Build.sysroot(abi)}"
      end

      if not build_options[:c_wrapper]
        cc = c_comp
      else
        cc = build_options[:c_wrapper] == true ? toolchain.c_compiler_name : build_options[:c_wrapper]
        cc = "#{build_dir_for_abi(abi)}/#{cc}"
        c_comp += ' ' + cflags if build_options[:cflags_in_c_wrapper]
        ldflags_wrapper_arg = build_options[:ldflags_in_c_wrapper] ? { before: ldflags, after: '' } : nil
        Build.gen_compiler_wrapper cc, c_comp, toolchain, build_options, '', ldflags_wrapper_arg
      end
    end

    ldflags.gsub!(/[ ]*-pie/, '') if build_options[:ldflags_no_pie]

    build_env['LC_MESSAGES'] = 'C'
    build_env['CC']          = cc
    build_env['CPP']         = "#{cc} #{cflags} -E"
    build_env['AR']          = toolchain.tool(arch, 'ar')
    build_env['RANLIB']      = toolchain.tool(arch, 'ranlib')
    build_env['READELF']     = toolchain.tool(arch, 'readelf')
    build_env['STRIP']       = toolchain.tool(arch, 'strip')
    build_env['CFLAGS']      = cflags
    build_env['LDFLAGS']     = ldflags

    if build_options[:use_cxx]
      if toolchain.standalone?
        cxx = toolchain.gxx
        cxxflags = cflags
      else
        cxx_comp = toolchain.cxx_compiler(arch, abi)
        cxx_comp += " --sysroot=#{Build.sysroot(abi)}" unless build_options[:sysroot_in_cflags]
        ldflags += ' ' + toolchain.search_path_for_stl_libs(abi)

        if not build_options[:cxx_wrapper]
          cxx = cxx_comp
        else
          cxx = build_options[:cxx_wrapper] == true ? toolchain.cxx_compiler_name : build_options[:cxx_wrapper]
          cxx = "#{build_dir_for_abi(abi)}/#{cxx}"
          ldflags_wrapper_arg = build_options[:ldflags_in_c_wrapper] ? { before: ldflags, after: '' } : nil
          Build.gen_compiler_wrapper cxx, cxx_comp, toolchain, build_options, '', ldflags_wrapper_arg
        end

        cxxflags = cflags + ' ' + toolchain.search_path_for_stl_includes(abi)
      end

      @build_env['CXX']      = cxx
      @build_env['CXXCPP']   = "#{cxx} #{cxxflags} -E"
      @build_env['CXXFLAGS'] = cxxflags
      @build_env['LDFLAGS']  = ldflags
    end
  end

  def copy_installed_files(abi)
    dirs = build_options[:copy_installed_dirs]
    install_dir = install_dir_for_abi(abi)
    FileUtils.mkdir_p package_dir
    dirs.each do |dir|
      case dir
      when 'bin', 'libexec', 'sbin'
        FileUtils.mkdir_p "#{package_dir}/#{dir}"
        FileUtils.cp_r "#{install_dir}/#{dir}", "#{package_dir}/#{dir}/#{abi}", preserve: true
      when 'etc', 'include', 'share', 'var'
        # copy files if they were not copied yet
        FileUtils.cp_r "#{install_dir}/#{dir}", package_dir, preserve: true unless Dir.exists? "#{package_dir}/#{dir}"
      when 'lib'
        # copy libs
        FileUtils.mkdir_p "#{package_dir}/libs"
        FileUtils.cp_r "#{install_dir}/lib", "#{package_dir}/libs/#{abi}", preserve: true
      else
        raise "unsupported installed dir name: #{dir}"
      end
    end
  end

  def write_build_info(package_dir)
    prop = { build_info: @host_build_info + @target_build_info }
    save_properties prop, package_dir
  end

  def copy_tests(release)
    src_tests_dir = "#{Build::VENDOR_TESTS_DIR}/#{file_name}"
    puts "tests dir: #{src_tests_dir}"
    if Dir.exists? src_tests_dir
      puts "coping tests..."
      dst_tests_dir = "#{package_dir}/#{TEST_DIR_BASENAME}"
      FileUtils.mkdir dst_tests_dir
      FileUtils.cp_r "#{src_tests_dir}/.", "#{dst_tests_dir}/"
      Dir["#{dst_tests_dir}/*"].each do |dir|
        android_mk_file = "#{dir}/jni/Android.mk"
        File.exist?(android_mk_file) && replace_lines_in_file(android_mk_file) do |line|
          case line
          when /\${version}/
            line.gsub '${version}', release.version
          when /\${module_subdir\((.*)\)}/
            dep_dir = @target_dep_dirs[Formula.make_target_fqn($1)]
            line.gsub /\${module_subdir.*}/, dep_dir.split(File::SEPARATOR)[-2..-1].join(File::SEPARATOR)
          else
            line
          end
        end
      end
    end
  end

  class << self

    def build_copy(*args)
      if args.size == 0
        @build_copy ? @build_copy : []
      else
        @build_copy = args
      end
    end

    def build_libs(*args)
      if args.size == 0
        @build_libs ? @build_libs : [ name ]
      else
        @build_libs = args
      end
    end
  end

  def build_copy
    self.class.build_copy
  end

  def build_libs
    self.class.build_libs
  end

  def copy_to_standalone_toolchain(release, arch, target_include_dir, target_lib_dir, _options)
    make_target_lib_dirs(arch, target_lib_dir)

    release_dir = release_directory(release)
    src_lib_dir = "#{release_dir}/libs"

    FileUtils.cp_r Dir["#{release_dir}/include/*"], target_include_dir

    case arch.name
    when 'arm'
      pkgconfig_src_base_dir = "#{src_lib_dir}/armeabi-v7a"
      # todo: it seems clang can't find required libs so we copy armveabi-v7a libs to a place where armeabi libs were
      #       gcc works fine without those copies
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a'),      "#{target_lib_dir}/lib/"
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a'),      "#{target_lib_dir}/lib/thumb/"
      #
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a'),      "#{target_lib_dir}/lib/armv7-a/"
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a'),      "#{target_lib_dir}/lib/armv7-a/thumb/"
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a-hard'), "#{target_lib_dir}/lib/armv7-a/hard/"
      FileUtils.cp_r toolchain_libs(src_lib_dir, 'armeabi-v7a-hard'), "#{target_lib_dir}/lib/armv7-a/thumb/hard/"
    when 'mips64', 'x86_64'
      pkgconfig_src_base_dir = "#{src_lib_dir}/#{arch.abis[0]}"
      FileUtils.cp_r toolchain_libs(src_lib_dir, arch.abis[0]), "#{target_lib_dir}/lib64/"
    else
      pkgconfig_src_base_dir = "#{src_lib_dir}/#{arch.abis[0]}"
      FileUtils.cp_r toolchain_libs(src_lib_dir, arch.abis[0]), "#{target_lib_dir}/lib/"
    end

    pkgconfig_dst_dir = "#{target_lib_dir}/lib/pkgconfig"
    Dir["#{pkgconfig_src_base_dir}/pkgconfig/*.pc"].each do |src_file|
      dst_file = "#{pkgconfig_dst_dir}/#{File.basename(src_file)}"
      FileUtils.cp src_file, dst_file
      update_standalone_pc_file dst_file
    end
  end

  def toolchain_libs(dir, abi)
    Dir["#{dir}/#{abi}/*"]
  end

  def update_standalone_pc_file(file)
    prefix_dir = File.dirname(File.dirname(File.dirname(file)))
    lib_dir = "${prefix}/lib"
    replace_lines_in_file(file) do |line|
      case line
      when /^prefix[ ]*=/
        "prefix=#{prefix_dir}"
      when /^libdir[ ]*=/
        "libdir=#{lib_dir}"
      else
        line
      end
    end
  end

  # some libraries use pthread_cancel to check whether pthread is in use
  # since we do not have pthread_cancel (at least right now) we must handle the issue by editing config.h
  def set_pthread_in_use_detection_hard(config_h_file)
    replace_lines_in_file(config_h_file) do |line|
      if line == '/* #undef PTHREAD_IN_USE_DETECTION_HARD */'
        '#define PTHREAD_IN_USE_DETECTION_HARD 1'
      else
        line
      end
    end
  end

  def clean_install_dir(abi)
    FileUtils.cd(install_dir_for_abi(abi)) do
      FileUtils.rm_rf Dir['lib/**/*.la']
      Dir['lib/**/*.a', 'lib/**/*.so', 'lib/**/*.so.*'].each { |f| FileUtils.rm f if File.symlink?(f) }
    end
  end

  # def target_dep_all_include_dirs(dirs)
  #   dirs.values.inject('') { |acc, dir| "#{acc} #{target_dep_include_dir(dir)}" }
  # end

  # def target_dep_all_lib_dirs(dirs, abi)
  #   dirs.values.inject('') { |acc, dir| "#{acc} #{target_dep_lib_dir(dir, abi)}" }
  # end

  def pc_prefix_template(release)
    "prefix=${ndk_dir}/packages/#{file_name}/#{release.version}"
  end

  def pc_libdir_template(abi)
    "libdir=${prefix}/libs/#{abi}"
  end

  def pc_includedir_template
    'includedir=${prefix}/include'
  end

  def pc_edit_file(file, release, abi)
    replace_lines_in_file(file) do |line|
      case line
      when /^prefix[ ]*=/      then pc_prefix_template(release)
      when /^libdir[ ]*=/      then pc_libdir_template(abi)
      when /^includedir[ ]*=/  then pc_includedir_template
      else
        line
      end
    end
  end

  def configure(*args)
    args = ["--host=#{host_for_abi(@build_abi)}"]          + args unless args.any? { |a| a.start_with?('--host=') }
    args = ["--prefix=#{install_dir_for_abi(@build_abi)}"] + args unless args.any? { |a| a.start_with?('--prefix=') }

    src_dir = build_options[:build_outside_source_tree] ? source_directory(@build_release) : '.'
    system "#{src_dir}/configure", *args
  end

  def make(*args)
    args = ['-j', num_jobs] + args unless args.include?('install')
    system 'make', *args
  end

  def ndk_build(*args)
    system "#{Global::NDK_DIR}/ndk-build", *args
  end

  private

  def binary_files(rel_dir)
    Dir["#{rel_dir}/*"].select { |a| ![SRC_DIR_BASENAME, Properties::FILE].include? File.basename(a) }
  end

  def package_dir
    "#{build_base_dir}/package"
  end

  def base_dir_for_abi(abi)
    "#{build_base_dir}/#{abi}"
  end

  def build_dir_for_abi(abi)
    "#{base_dir_for_abi(abi)}/build"
  end

  def test_dir_for(abi, toolchain)
    File.join(test_base_dir, abi, toolchain)
  end

  def install_dir_for_abi(abi)
    "#{base_dir_for_abi(abi)}/install"
  end

  def host_for_abi(abi)
    Build.arch_for_abi(abi).host
  end

  def update_pc_files(release)
    Dir["#{release_directory(release)}/libs/**/*.pc"].each do |file|
      unless File.symlink? file
        replace_lines_in_file(file) { |line| line.sub(/\${ndk_dir}/, Global::NDK_DIR) }
      end
    end
  end
end
