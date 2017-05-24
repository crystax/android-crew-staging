require_relative 'platform.rb'
require_relative 'formula.rb'

class HostBase < Formula

  include Properties

  namespace :host

  LIST_FILE_EXT = 'list'

  def initialize(path)
    super path

    # todo: handle platform dependant installations
    # mark installed releases and sources
    releases.each { |r| r.update get_properties(release_directory(r, Global::PLATFORM_NAME)) }
  end

  def release_directory(release, platform_name)
    File.join(Global::SERVICE_DIR, name, platform_name, release.version)
  end

  def uninstall_archive(release, platform_name)
    rel_dir = release_directory(release, platform_name)
    remove_archive_files rel_dir, platform_name
    FileUtils.rm_rf rel_dir
  end

  def install_archive(release, archive, platform_name)
    # todo: handle multi platform
    #       add platform support into Release class
    prev_release = releases.select { |r| r.installed? }.last
    uninstall_archive prev_release, platform_name if prev_release

    rel_dir = release_directory(release, platform_name)
    FileUtils.mkdir_p rel_dir

    Utils.unpack archive, Global::NDK_DIR
    FileUtils.mv File.join(Global::NDK_DIR, list_filename(platform_name)), rel_dir

    prop = get_properties(rel_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def archive_filename(release, platform_name = Global::PLATFORM_NAME)
    "#{file_name}-#{release}-#{platform_name}.tar.xz"
  end

  def cache_file(release, plaform_name)
    File.join(Global.pkg_cache_dir(self), archive_filename(release, plaform_name))
  end

  def build_base_dir
    File.join Build::BASE_HOST_DIR, file_name
  end

  def src_dir
    File.join build_base_dir, 'src'
  end

  def base_dir_for_platform(platform_name)
    File.join build_base_dir, platform_name
  end

  def build_dir_for_platform(platform_name)
    File.join base_dir_for_platform(platform_name), 'build'
  end

  def package_dir_for_platform(platform_name)
    File.join base_dir_for_platform(platform_name), 'package'
  end

  def build_log_file(platform_name)
    File.join base_dir_for_platform(platform_name), 'build.log'
  end

  def sha256_sum(release, platform_name = Global::PLATFORM_NAME)
    release.shasum(Platform.new(platform_name).to_sym)
  end

  def update_shasum(release, platform)
    archive = cache_file(release, platform.name)
    release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }

    ver = release.version
    cxver = release.crystax_version
    sum = release.shasum(platform.to_sym)
    release_regexp = /^[[:space:]]*release[[:space:]]+version:[[:space:]]+'#{ver}',[[:space:]]+crystax_version:[[:space:]]+#{cxver}/
    platform_regexp = /(.*#{platform.to_sym}:\s+')(\h+)('.*)/
    lines = []
    state = :copy
    File.foreach(path) do |l|
      case state
      when :updated
        lines << l
      when :copy
        if  l !~ release_regexp
          lines << l
        else
          if l !~ platform_regexp
            state = :updating
            lines << l
          else
            state = :updated
            lines << l.sub(platform_regexp, '\1' + sum + '\3')
          end
        end
      when :updating
        if l !~ platform_regexp
          lines << l
        else
          state = :updated
          lines << l.sub(platform_regexp, '\1' + sum + '\3')
        end
      else
        raise "in formula #{File.basename(file_name)} bad state #{state} on line: #{l}"
      end
    end

    File.open(path, 'w') { |f| f.puts lines }

    # we want archive modification time to be after formula file modification time
    # otherwise we'll be constantly rebuilding formulas for nothing
    FileUtils.touch archive
  end

  def write_file_list(package_dir, platform_name)
    FileUtils.cd(package_dir) do
      list = Dir.glob('**/*', File::FNM_DOTMATCH).delete_if { |e| e.end_with? ('.') }
      File.open(list_filename(platform_name), 'w') { |f| list.each { |l| f.puts l } }
    end
  end

  def remove_archive_files(rel_dir, platform_name)
    dirs = []
    FileUtils.cd(Global::NDK_DIR) do
      # remove normal files
      File.read(File.join(rel_dir, list_filename(platform_name))).split("\n").each do |f|
        case
        when File.symlink?(f)
          FileUtils.rm f
        when File.directory?(f)
          dirs << f
        when File.file?(f)
          FileUtils.rm f
        when !File.exist?(f)
          warning "#{name}, #{platform_name}: file not exists: #{f}"
        else
          raise ""#{name}, #{platform_name}: strange file in file list: #{f}"
        end
      end
      # remove dirs
      dirs.sort.reverse_each { |d| FileUtils.rmdir d if Dir['d/*'].empty? }
    end
  # todo: remove this hack
  rescue => e
    warning "failed to remove archive files: #{e}"
  end

  def list_filename(platform_name)
    "#{platform_name}.#{LIST_FILE_EXT}"
  end
end
