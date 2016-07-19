# require 'digest'
# require_relative 'formula.rb'
# require_relative 'platform.rb'
# require_relative 'build.rb'
# require_relative 'build_options.rb'


class Part < Formula

  # For every Part there is a file in the parts directory with the name that corresponds to the part's name.
  # Each such file contains the list of the installed releases of the respective part.
  #
  def initialize(path)
    super(path)

    if not irs = read_installed
      # todo: output warning
    else
      releases.each do |r|
        m = irs.select { |i| i.version == r.version }
        r.installed = m[0].crystax_version if m.size > 0
      end
    end
  end

  # def home_directory(platform_name)
  #   File.join(Global.engine_dir(platform_name), file_name)
  # end

  # def release_directory(release, platform_name = Global::PLATFORM_NAME)
  #   File.join(home_directory(platform_name), release.to_s)
  # end

  # def active_version(engine_dir = Global::ENGINE_DIR)
  #   Utility.active_version file_name, engine_dir
  # end

  def download_base
    "#{Global::DOWNLOAD_BASE}/parts"
  end

  def type
    :ndk_part
  end

  # def role
  #   self.class.role
  # end

  # def core?
  #   role == :core
  # end

  # def build_dependencies
  #   self.class.build_dependencies ? self.class.build_dependencies : []
  # end

  # class << self
  #   attr_rw :role
  #   attr_reader :build_dependencies

  #   def build_depends_on(name, options = {})
  #     @build_dependencies = [] unless @build_dependencies
  #     @build_dependencies << Formula::Dependency.new(name, options)
  #   end
  # end

  # def build_package(release, options, dep_dirs)
  #   platforms = options.platforms.map { |name| Platform.new(name) }
  #   puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

  #   @num_jobs = options.num_jobs

  #   # create required directories and download sources
  #   FileUtils.rm_rf build_base_dir
  #   puts "= preparing source code"
  #   prepare_source_code release, File.dirname(src_dir), File.basename(src_dir), ' '
  #   if options.source_only?
  #     puts "Only sources were requested, loook for them in #{build_base_dir}"
  #     return
  #   end

  #   platforms.each do |platform|
  #     puts "= building for #{platform.name}"
  #     base_dir = base_dir_for_platform(platform)
  #     build_dir = build_dir_for_platform(platform)
  #     install_dir = install_dir_for_platform(platform, release)
  #     FileUtils.mkdir_p [build_dir, install_dir]
  #     @log_file = build_log_file(platform)
  #     #
  #     build_env.clear
  #     FileUtils.cd(build_dir) { build_for_platform platform, release, options, dep_dirs }
  #     next if options.build_only?
  #     #
  #     archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
  #     Utils.pack archive, base_dir, ARCHIVE_TOP_DIR
  #     #
  #     if options.update_shasum?
  #       release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
  #       update_shasum release, platform
  #     end
  #     install_archive release, archive, platform.name
  #     FileUtils.rm_rf base_dir unless options.no_clean?
  #   end

  #   if options.no_clean?
  #     puts "No cleanup, for build artifacts see #{build_base_dir}"
  #   else
  #     FileUtils.rm_rf build_base_dir
  #   end
  # end

  # def archive_filename(release, platform_name = Global::PLATFORM_NAME)
  #   "#{file_name}-#{Formula.package_version(release)}-#{platform_name}.tar.xz"
  # end

  # def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
  #   rel_dir = release_directory(release, platform_name)
  #   FileUtils.rm_rf rel_dir
  #   # use system tar while updating bsdtar utility
  #   Utils.reset_tar_prog if name == 'bsdtar'
  #   Utils.unpack archive, ndk_dir
  #   write_active_file File.dirname(rel_dir), release
  #   Utils.reset_tar_prog if name == 'bsdtar'
  #   release.installed = release.crystax_version
  # end

  private

  def installed_file_name
    File.join(Global::SERVICE_DIR, "#{file_name}.txt")
  end
  
  def read_installed
    irs = []
    file = installed_file_name
    if File.exist? file
      File.readlines(file).each do |l|
        ver, cxver = Formula.split_package_version(l)
        irs << Release.new(ver, cxver)
      end
    end
    irs
  end

  # def sha256_sum(release)
  #   release.shasum(Global::PLATFORM_NAME.gsub(/-/, '_').to_sym)
  # end

  # def write_active_file(home_dir, release)
  #   file = File.join(home_dir, ACTIVE_FILE_NAME)
  #   File.open(file, 'w') { |f| f.puts release.to_s }
  # end

  # def build_base_dir
  #   File.join Build::BASE_HOST_DIR, file_name
  # end

  # def src_dir
  #   File.join build_base_dir, 'src'
  # end

  # def base_dir_for_platform(platform)
  #   File.join build_base_dir, platform.name
  # end

  # def build_dir_for_platform(platform)
  #   File.join base_dir_for_platform(platform), 'build'
  # end

  # def install_dir_for_platform(platform, release)
  #   File.join base_dir_for_platform(platform), 'prebuilt', platform.name, 'crew', file_name, release.to_s
  # end

  # def build_log_file(platform)
  #   File.join base_dir_for_platform(platform), 'build.log'
  # end

  # def update_shasum(release, platform)
  #   ver = release.version
  #   cxver = release.crystax_version
  #   sum = release.shasum(platform.to_sym)
  #   release_regexp = /^[[:space:]]*release[[:space:]]+version:[[:space:]]+'#{ver}',[[:space:]]+crystax_version:[[:space:]]+#{cxver}/
  #   platform_regexp = /#{platform.to_sym}:/
  #   lines = []
  #   state = :copy
  #   File.foreach(path) do |l|
  #     case state
  #     when :updated
  #       lines << l
  #     when :copy
  #       if  l !~ release_regexp
  #         lines << l
  #       else
  #         if l !~ platform_regexp
  #           state = :updating
  #           lines << l
  #         else
  #           state = :updated
  #           lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
  #         end
  #       end
  #     when :updating
  #       if l !~ platform_regexp
  #         lines << l
  #       else
  #         state = :updated
  #         lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
  #       end
  #     else
  #       raise "in formula #{File.basename(file_name)} bad state #{state} on line: #{l}"
  #     end
  #   end

  #   File.open(path, 'w') { |f| f.puts lines }
  # end
end
