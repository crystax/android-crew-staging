require_relative 'shasum.rb'
require_relative 'platform.rb'
require_relative 'formula.rb'

class HostBase < Formula

  include Properties

  namespace :host

  LIST_FILE = 'list'

  def initialize(path)
    super path

    # todo: handle platform dependant installations
    # mark installed releases and sources
    releases.each { |r| r.update get_properties(release_directory(r, Global::PLATFORM_NAME)) }
  end

  def release_directory(release, platform_name)
    File.join(Global::SERVICE_DIR, file_name, platform_name, release.version)
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
    FileUtils.mv File.join(Global::NDK_DIR, LIST_FILE), rel_dir

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

  def read_shasum(release, platform_name = Global::PLATFORM_NAME)
    Shasum.read fqn, release, platform_name
  end

  def update_shasum(release, platform_name)
    archive = cache_file(release, platform_name)
    Shasum.update fqn, release, platform_name, Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
  end

  def write_file_list(package_dir, platform_name)
    FileUtils.cd(package_dir) do
      list = Dir.glob('**/*', File::FNM_DOTMATCH).delete_if { |e| e.end_with? ('.') }
      File.open(LIST_FILE, 'w') { |f| list.each { |l| f.puts l } }
    end
  end

  def remove_archive_files(rel_dir, platform_name)
    dirs = []
    FileUtils.cd(Global::NDK_DIR) do
      # remove normal files
      File.read(File.join(rel_dir, LIST_FILE)).split("\n").each do |f|
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
end
