require 'uri'
require 'tmpdir'
require 'fileutils'
require_relative 'formula.rb'
require_relative 'release.rb'
require_relative 'build.rb'


class Library < Formula

  SRC_DIR_BASENAME = 'src'

  def release_directory(release)
    File.join(Global::HOLD_DIR, name, release.version)
  end

  def download_base
    "#{Global::DOWNLOAD_BASE}/packages"
  end

  def type
    :library
  end

  def uninstall(release)
    puts "removing #{name}:#{release.version}"
    rel_dir = release_directory(release)
    if not release.sources_installed?
      FileUtils.rm_rf rel_dir
    else
      props = get_properties(rel_dir)
      FileUtils.rm_rf binary_files(rel_dir)
      props[:installed] = false
      save_properties prop, rel_dir
    end
    release.installed = false
  end

  def install_source(release)
    puts "installing source code for #{name}:#{release}"
    rel_dir = release_directory(release)
    prop = get_properties(rel_dir)
    if prop[:crystax_version] == nil
      prop[:crystax_version] = release.crystax_version
      FileUtils.mkdir_p rel_dir
    end

    ver_url = version_url(release.version)
    archive = "#{Global::CACHE_DIR}/#{File.basename(URI.parse(ver_url).path)}"
    if File.exists? archive
      puts "= using cached file #{archive}"
    else
      puts "= downloading #{ver_url}"
      Utils.download(ver_url, archive)
    end

    # todo: handle option source_archive_without_top_dir: true
    old_dir = Dir["#{rel_dir}/*"]
    puts "= unpacking #{File.basename(archive)} into #{rel_dir}"
    Utils.unpack(archive, rel_dir)
    new_dir = Dir["#{rel_dir}/*"]
    diff = old_dir.empty? ? new_dir : new_dir - old_dir
    raise "source archive does not have top directory, diff: #{diff}" if diff.count != 1
    FileUtils.cd(rel_dir) { FileUtils.mv diff[0], SRC_DIR_BASENAME }

    prop[:source_installed] = true
    save_properties prop, rel_dir
  end

  def build_package(release)
    puts "Building #{name} #{release} for architectures: #{Build::ARCH_LIST.map{|a| a.name}.join(' ')}"
    FileUtils.rm_rf "#{Build::BASE_DIR}/#{name}"

    src_dir = "#{release_directory(release)}/#{SRC_DIR_BASENAME}"
    Build::ARCH_LIST.each do |arch|
      print "= building for architecture: #{arch.name}; abis: [ "
      arch.abis.each do |abi|
        print "#{abi} "
        FileUtils.mkdir_p base_dir_for_abi(abi)
        build_dir = build_dir_for_abi(abi)
        FileUtils.cp_r "#{src_dir}/.", build_dir
        prepare_env_for abi
        FileUtils.cd(build_dir) { build_for_abi(abi) }
        package_libs_and_headers abi
      end
      puts "]"
    end
    Build.gen_android_mk "#{package_dir}/Android.mk", build_libs

    # pack archive and copy into cache dir
    archive = "#{Build::CACHE_DIR}/#{archive_filename(release)}"
    puts "Creating archive file #{archive}"
    Utils.pack(archive, package_dir)

    # install into packages (and update props if any)
    puts "Unpacking archive into #{release_directory(release)}"
    install_release_archive release, archive

    # calculate and update shasum if asked for
    # todo:
    # full cleanup if no-clean was not specified
    # todo:
  end

  def self.build_libs(*args)
    if args.size == 0
      @build_libs ? @build_libs : [ name ]
    else
      @build_libs = args
    end
  end

  def build_libs
    self.class.build_libs
  end

  private

  def version_url(version)
    url.gsub('{version}', version)
  end

  def archive_filename(release)
    "#{name}-#{Formula.package_version(release)}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(:android)
  end

  def install_archive(release, archive)
    rel_dir = release_directory(release)
    FileUtils.rm_rf binary_files(rel_dir)
    Utils.unpack archive, rel_dir
    # todo:
    #update_root_android_mk release
  end

  def binary_files(rel_dir)
    Dir["#{rel_dir}/*"].select{ |a| File.basename(a) != SRC_DIR_BASENAME }
  end

  def package_dir
    "#{Build::BASE_DIR}/#{name}/package"
  end

  def base_dir_for_abi(abi)
    "#{Build::BASE_DIR}/#{name}/#{abi}"
  end

  def build_dir_for_abi(abi)
    "#{base_dir_for_abi(abi)}/build"
  end

  def install_dir_for_abi(abi)
    "#{base_dir_for_abi(abi)}/install"
  end

  def log_file_for_abi(abi)
    "#{base_dir_for_abi(abi)}/build.log"
  end

  def host_for_abi(abi)
    Build.arch_for_abi(abi).host
  end

  def prepare_env_for(abi)
    @log_file = log_file_for_abi(abi)

    cflags  = Build.cflags(abi)
    ldflags = Build.ldflags(abi)
    gcc, ar, ranlib = Build.tools(abi)

    gcc_wrapper = "#{build_dir_for_abi(abi)}/cc"
    Build.gen_fix_soname_wrapper(gcc_wrapper, gcc)

    @env = {'CC'      => gcc_wrapper,
            'CPP'     => "#{gcc_wrapper} #{cflags} -E",
            'AR'      => ar,
            'RANLIB'  => ranlib,
            'CFLAGS'  => cflags,
            'LDFLAGS' => ldflags
           }
  end

  def package_libs_and_headers(abi)
    pkg_dir = package_dir
    install_dir = install_dir_for_abi(abi)
    # copy headers if they were not copied yet
    inc_dir = "#{pkg_dir}/include"
    if !Dir.exists? inc_dir
      FileUtils.mkdir_p pkg_dir
      FileUtils.cp_r "#{install_dir}/include", pkg_dir
    end
    # copy libs
    libs_dir = "#{pkg_dir}/libs/#{abi}"
    FileUtils.mkdir_p libs_dir
    build_libs.each do |lib|
      FileUtils.cp "#{install_dir}/lib/#{lib}.a",  libs_dir
      FileUtils.cp "#{install_dir}/lib/#{lib}.so", libs_dir
    end
  end

  def system(*args)
    cmd = args.join(' ')
    File.open(@log_file, "a") do |log|
      log.puts "== env: #{@env}"
      log.puts "== cmd started: #{cmd}"

      rc = 0
      Open3.popen2e(@env, cmd) do |_, out, wt|
        ot = Thread.start { out.read.split("\n").each { |l| log.puts l } }
        ot.join
        rc = wt && wt.value.exitstatus
      end
      log.puts "== cmd finished: exit code: #{rc} cmd: #{cmd}"
      raise "command failed with code: #{rc}; see #{@log_file} for details" unless rc == 0
    end
  end

  # # $(call import-module,libjpeg/9a)
  # def update_root_android_mk(release)
  #   android_mk = "#{File.dirname(release_directory(release))}/Android.mk"
  #   new_ver = release.version
  #   if not File.exists? android_mk
  #     write_root_android_mk android_mk, new_ver
  #   else
  #     prev_ver = File.read(android_mk).strip.delete("()").split('/')[1]
  #     new_ver = release.version
  #     if more_recent_version(prev_ver, new_ver) == new_ver
  #       write_root_android_mk android_mk, new_ver
  #     end
  #   end
  # end

  # def write_android_mk(file, ver)
  #   File.open(file, 'w') { |f| f.puts "include $(call my-dir)/#{ver}/Android.mk" }
  # end
end
