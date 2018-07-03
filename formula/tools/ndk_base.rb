class NdkBase < HostBase

  desc "Basic NDK directory structure, sources, build tools and scripts"
  name 'ndk-base'
  homepage "https://www.crystax.net"

  release '11', crystax: 15

  def install_archive(release, archive, platform_name)
    # disable warnings since ndk-base archive contains symlinks
    #Global::set_options(['-W'])
    super release, archive, platform_name
  end

  # todo: when libcrystax will be moved to a separate repository it'll be easy to just copy ndk directory
  #       and remove unneeded files
  def prepare_source_code
    commit = nil
    FileUtils.cd(Global::NDK_DIR) { commit = Utils.run_command('git', 'log', '-1', '--format=format:%H%n').strip }
    system 'git', 'clone', Global::NDK_DIR, src_dir
    FileUtils.cd(src_dir) do
      system 'git', 'checkout', commit
      FileUtils.rm_rf '.git'
    end
  end

  def build(release, options, host_dep_dirs, target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    FileUtils.rm_rf build_base_dir
    FileUtils.mkdir_p build_base_dir

    self.num_jobs = options.num_jobs
    self.log_file = File.join(build_base_dir, 'build.log')

    puts "= preparing source code"
    prepare_source_code

    if options.source_only?
      puts "Only sources were requested, find them in #{src_dir}"
      return
    end

    platforms.each do |platform|
      puts "= building for #{platform.name}"

      base_dir = base_dir_for_platform(platform.name)
      install_dir = File.join(base_dir, 'install')
      FileUtils.mkdir_p install_dir
      self.log_file = build_log_file(platform.name)

      FileUtils.cd(src_dir)     { FileUtils.cp_r Dir["*"], install_dir }
      FileUtils.cd(install_dir) { FileUtils.rm Dir['*.cmd'] unless platform.target_os == 'windows' }

      next if options.build_only?

      write_file_list install_dir, platform.name

      archive = cache_file(release, platform.name)
      Utils.pack archive, install_dir

      update_shasum release, platform.name            if options.update_shasum?
      install_archive release, archive, platform.name if options.install?
      FileUtils.rm_rf base_dir                        if options.clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  def all_files_cwd
    Dir['*'] + Dir['.*'] - ['.', '..']
  end
end
