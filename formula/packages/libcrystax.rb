class Libcrystax < BasePackage

  desc "Crystax Library, the Heart of the Crystax NDK"
  name 'libcrystax'
  # todo:
  #homepage ""
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release version: '1', crystax_version: 1, sha256: '0'

  # todo:
  #build_depends_on 'platforms'
  #build_depends_on default_gcc_compiler

  # todo: move method to the BasePackage class?
  def install_archive(release, archive, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    FileUtils.rm_rf "#{ndk_dir}/#{archive_sub_dir}"
    puts "Unpacking archive into #{ndk_dir}/#{archive_sub_dir}"
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

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

      arch_list.each do |arch|
      puts "= building for architecture: #{arch.name}"
      arch_build_dir = File.join(build_base_dir, arch.name)
      arch.abis_to_build.each do |abi|
        puts "  building for abi: #{abi}"
        build_dir = File.join(arch_build_dir, abi, 'build')
        FileUtils.mkdir_p build_dir
        FileUtils.cd(build_dir) { [:static, :shared].each { |lt| build_for_abi abi, release, lib_type: lt } }
        FileUtils.cp_r "#{Global::NDK_DIR}/#{archive_sub_dir}", dst_dir unless options.build_only?
      end
      FileUtils.rm_rf arch_build_dir unless options.no_clean?
    end

    if options.build_only?
      puts "Build only, no packaging and installing"
    else
      # pack archive and copy into cache dir
      # todo: use global cache dir or build cache dir?
      archive = "#{Global::CACHE_DIR}/#{archive_filename(release)}"
      puts "Creating archive file #{archive}"
      Utils.pack(archive, package_dir)

      install_archive release, archive if options.install?
    end

    if options.update_shasum?
      release.shasum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
      update_shasum release
    end

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
    crystax_dir = "#{Global::NDK_DIR}/#{File.dirname(archive_sub_dir)}"

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

  def package_dir
    "#{build_base_dir}/package"
  end

  def archive_sub_dir
    "sources/crystax/libs"
  end
end
