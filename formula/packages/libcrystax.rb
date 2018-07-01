class Libcrystax < BasePackage

  include SingleVersion

  desc "Crystax Library, the Heart of the Crystax NDK"
  name 'libcrystax'

  release '1', crystax: 9

  package_info root_dir: ['libs']

  # todo:
  build_depends_on 'platforms'
  #build_depends_on default_gcc_compiler

  def release_directory(_release = nil, _platform_ndk = nil)
    "#{Global::NDK_DIR}/#{archive_sub_dir}"
  end

  # todo: move method to the BasePackage class?
  def install_archive(release, archive, _platform_name = nil)
    prop_dir = properties_directory(release)
    FileUtils.mkdir_p prop_dir
    prop = get_properties(prop_dir)

    FileUtils.rm_rf release_directory
    puts "Unpacking archive into #{release_directory}"
    Utils.unpack archive, Global::NDK_DIR

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, prop_dir

    release.installed = release.crystax_version
  end

  def build(release, options, _host_dep_dirs, _target_dep_dirs)
    arch_list = Build.abis_to_arch_list(options.abis)
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"

    base_dir = build_base_dir
    FileUtils.rm_rf base_dir
    @log_file = build_log_file
    @num_jobs = options.num_jobs

    dst_dir = "#{package_dir}/#{File.dirname(archive_sub_dir)}"
    FileUtils.mkdir_p dst_dir

    #recreate_symlinks_to_vendor_and_test_dirs

    arch_list.each do |arch|
      puts "= building for architecture: #{arch.name}"
      arch_build_dir = File.join(build_base_dir, arch.name)
      arch.abis_to_build.each do |abi|
        puts "  building for abi: #{abi}"
        build_dir = File.join(arch_build_dir, abi, 'build')
        FileUtils.mkdir_p build_dir
        FileUtils.cd(build_dir) do
          [:static, :shared].each do |lt|
            build_for_abi abi, release, lib_type: lt
            FileUtils.cp_r release_directory, dst_dir unless options.build_only?
          end
        end
      end
      FileUtils.rm_rf arch_build_dir unless options.no_clean?
    end

    if options.build_only?
      puts "Build only, no packaging and installing"
    else
      archive = cache_file(release)
      puts "Creating archive file #{archive}"
      Utils.pack(archive, package_dir)
      clean_deb_cache release, options.abis

      install_archive release, archive if options.install?
    end

    update_shasum release if options.update_shasum?

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{base_dir}"
    else
      FileUtils.rm_rf base_dir
    end
  end

  def build_for_abi(abi, release, options)
    lib_type = options[:lib_type]
    build_dir = File.join(Dir.pwd, lib_type.to_s)
    FileUtils.mkdir build_dir
    crystax_dir = File.dirname(release_directory)

    # todo: why strictly gcc 4.9 must be used?
    args = [lib_type,
            'V=1',
            "NDK=#{Global::NDK_DIR}",
            "ABI=#{abi}",
            "OBJDIR=#{build_dir}",
            "TVS=gcc4.9"
           ]

    FileUtils.cd(build_dir) do
      system 'make', '-C', crystax_dir, 'clean'
      system 'make', '-C', crystax_dir, '-j', num_jobs, *args
    end
  end

  def copy_to_standalone_toolchain(_release, arch, _target_include_dir, target_lib_dir, _options)
    make_target_lib_dirs(arch, target_lib_dir)

    crystax_libs_dir = archive_sub_dir

    case arch.name
    when 'arm'
      # todo: here we copy armeabi-v7a libs in two sets of directories
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a/libcrystax.*"],            "#{target_lib_dir}/lib/"
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a/thumb/libcrystax.*"],      "#{target_lib_dir}/lib/thumb/"
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a/libcrystax.*"],            "#{target_lib_dir}/lib/armv7-a/"
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a/thumb/libcrystax.*"],      "#{target_lib_dir}/lib/armv7-a/thumb/"
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a-hard/libcrystax.*"],       "#{target_lib_dir}/lib/armv7-a/hard/"
      FileUtils.cp Dir["#{crystax_libs_dir}/armeabi-v7a-hard/thumb/libcrystax.*"], "#{target_lib_dir}/lib/armv7-a/thumb/hard/"
    when 'mips'
      FileUtils.cp Dir["#{crystax_libs_dir}/mips/libcrystax.*"],    "#{target_lib_dir}/lib"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips/r2/libcrystax.*"], "#{target_lib_dir}/libr2"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips/r6/libcrystax.*"], "#{target_lib_dir}/libr6"
    when 'mips64'
      FileUtils.cp Dir["#{crystax_libs_dir}/mips64/libcrystax.*"],         "#{target_lib_dir}/lib64/"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips64/r2/libcrystax.*"],      "#{target_lib_dir}/lib64r2/"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips64/lib32/libcrystax.*"],   "#{target_lib_dir}/lib/"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips64/lib32r2/libcrystax.*"], "#{target_lib_dir}/libr2/"
      FileUtils.cp Dir["#{crystax_libs_dir}/mips64/lib32r6/libcrystax.*"], "#{target_lib_dir}/libr6/"
    when 'x86_64'
      FileUtils.cp Dir["#{crystax_libs_dir}/x86_64/libcrystax.*"],     "#{target_lib_dir}/lib64/"
      FileUtils.cp Dir["#{crystax_libs_dir}/x86_64/32/libcrystax.*"],  "#{target_lib_dir}/lib/"
      FileUtils.cp Dir["#{crystax_libs_dir}/x86_64/x32/libcrystax.*"], "#{target_lib_dir}/libx32/"
    else
      FileUtils.cp Dir["#{crystax_libs_dir}/#{arch.abis[0]}/libcrystax.*"], "#{target_lib_dir}/lib/"
    end
  end

  def copy_to_deb_data_dir(package_dir, data_dir, abi, deb_type = :bin)
    case deb_type
    when :bin
      dst_dir = "#{data_dir}/lib"
      FileUtils.mkdir_p dst_dir
      FileUtils.cp Dir["#{package_dir}/sources/crystax/libs/#{abi}/*.so"], dst_dir
    else
      raise "unsupported deb package type: #{deb_type}"
    end
  end

  def package_dir
    "#{build_base_dir}/package"
  end

  def archive_sub_dir
    "sources/crystax/libs"
  end

  # def recreate_symlinks_to_vendor_and_test_dirs
  #   crystax_dir = File.dirname(release_directory)
  #   vendor_dir = "#{crystax_dir}/vendor"
  #   if not Dir.exist? vendor_dir
  #     FileUtils.mkdir_p vendor_dir
  #     FileUtils.cd(vendor_dir) do
  #       FileUtils.symlink '../../../../../toolchain/llvm-3.6/compiler-rt', 'compiler-rt'
  #       FileUtils.symlink '../../../../../vendor/freebsd',                 'freebsd'
  #       FileUtils.symlink '../../../../../vendor/libkqueue',               'libkqueue'
  #       FileUtils.symlink '../../../../../vendor/libpwq',                  'libpwq'
  #       FileUtils.symlink '../../../../../vendor/musl',                    'musl'
  #     end
  #   end

  #   tests_dir = "#{crystax_dir}/tests"
  #   if not Dir.exist? tests_dir
  #     FileUtils.mkdir_p tests_dir
  #     FileUtils.cd(tests_dir) do
  #       FileUtils.symlink '../../../../bionic/tests',             'bionic'
  #       FileUtils.symlink '../../../../../vendor/libkqueue/test', 'libkqueue'
  #       FileUtils.symlink '../../../../../vendor/libpwq/testing', 'libpwq'
  #       FileUtils.symlink '../../../../../vendor/openpts',        'openpts'
  #     end
  #   end
  # end
end
