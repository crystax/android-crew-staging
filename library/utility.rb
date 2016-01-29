require_relative 'formula.rb'
require_relative 'platform.rb'
require_relative 'build.rb'
require_relative 'build_options.rb'


class Utility < Formula

  ARCHIVE_TOP_DIR = 'prebuilt'

  # For utilities a release considered as 'installed' only if it's version is equal
  # to the one saved in the 'active' file.
  #
  # Utility ctor called with :no_active_file from the NDK's build scripts
  # in the case we should just mark all releases as 'uninstalled'
  def initialize(path, *options)
    super(path)

    if not options.include? :no_active_file
      ver, cxver = Formula.split_package_version(Global::active_util_version(name))
      releases.each { |r| r.installed = cxver if r.version == ver }
    end
  end

  def home_directory
    File.join(Global::ENGINE_DIR, name)
  end

  def release_directory(release)
    File.join(home_directory, release.to_s)
  end

  def active_version
    File.read(Global.active_file_path(name)).split("\n")[0]
  end

  def download_base
    "#{Global::DOWNLOAD_BASE}/utilities"
  end

  def type
    :utility
  end

  def build_package(release, options)
    # todo:
    #platforms = options.platforms
    platforms = [Platform.new('darwin-x86_64')]
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    @num_jobs = options.num_jobs

    # create required directories and download sources
    FileUtils.rm_rf build_base_dir
    puts "= preparing source code"
    prepare_source_code release, File.dirname(src_dir), File.basename(src_dir), ' '

    platforms.each do |platform|
      puts "= building for #{platform.name}"
      base_dir = base_dir_for_platform(platform)
      build_dir = build_dir_for_platform(platform)
      install_dir = install_dir_for_platform(platform, release)
      FileUtils.mkdir_p [build_dir, install_dir]
      @log_file = build_log_file(platform)
      # build
      FileUtils.cd(build_dir) { build_for_platform platform, release, options }
      # todo: check options
      # package
      archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
      FileUtils.rm_f archive
      args = ['-C', base_dir, '-Jcf', archive, ARCHIVE_TOP_DIR]
      Utils.run_command 'tar', *args
      # todo: update sha sum
      # todo: install if same platform
      #
      FileUtils.rm_rf base_dir unless options.no_clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  private

  def archive_filename(release, platform_name = Global::PLATFORM_NAME)
    "#{name}-#{Formula.package_version(release)}-#{platform_name}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(Global::PLATFORM.gsub(/-/, '_').to_sym)
  end

  def install_archive(release, archive)
    rel_dir = release_directory(release)
    FileUtils.rm_rf rel_dir
    FileUtils.mkdir_p rel_dir
    Utils.unpack archive, Global::NDK_DIR
    write_active_file File.basename(rel_dir)
  end

  def write_active_file(version)
    File.open(Global.active_file_path(name), 'w') { |f| f.puts version }
  end

  def build_base_dir
    File.join Build::BASE_HOST_DIR, name
  end

  def src_dir
    File.join build_base_dir, 'src'
  end

  def base_dir_for_platform(platform)
    File.join build_base_dir, platform.name
  end

  def build_dir_for_platform(platform)
    File.join base_dir_for_platform(platform), 'build'
  end

  def install_dir_for_platform(platform, release)
    File.join base_dir_for_platform(platform), 'prebuilt', platform.name, 'crew', name, release.to_s
  end

  def build_log_file(platform)
    File.join base_dir_for_platform(platform), 'build.log'
  end

  # def package_dir
  #   File.join build_base_dir, 'package'
  # end
end
