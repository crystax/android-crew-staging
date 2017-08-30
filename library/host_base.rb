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

  def upgrading_ruby_on_windows?
    name == 'ruby' and Global::OS == 'windows'
  end

  def postpone_dir
    "#{Global::NDK_DIR}/postpone"
  end

  def ruby_upgrade_script
    "#{postpone_dir}/upgrade.cmd"
  end

  def uninstall_archive(release, platform_name)
    rel_dir = release_directory(release, platform_name)
    if upgrading_ruby_on_windows?
      gen_ruby_upgrade_cmd_script rel_dir
    else
      remove_archive_files rel_dir, platform_name
    end
    FileUtils.rm_rf rel_dir
  end

  def install_archive(release, archive, platform_name)
    # todo: handle multi platform
    #       add platform support into Release class
    prev_release = releases.select { |r| r.installed? }.last
    uninstall_archive prev_release, platform_name if prev_release

    rel_dir = release_directory(release, platform_name)
    FileUtils.mkdir_p rel_dir

    target_dir = (upgrading_ruby_on_windows? == true) ? postpone_dir : Global::NDK_DIR
    Utils.unpack archive, target_dir
    FileUtils.mv File.join(target_dir, LIST_FILE), rel_dir

    prop = get_properties(rel_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def archive_filename(release, platform_name = Global::PLATFORM_NAME)
    "#{file_name}-#{release}-#{platform_name}.#{Global::ARCH_EXT}"
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
    Shasum.read qfn, release, platform_name
  end

  def update_shasum(release, platform_name)
    archive = cache_file(release, platform_name)
    Shasum.update qfn, release, platform_name, Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
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
          raise "#{name}, #{platform_name}: strange file in file list: #{f}"
        end
      end
      # remove dirs
      dirs.sort.uniq.reverse_each { |d| FileUtils.rmdir d if Dir['d/*'].empty? }
    end
  # todo: remove this hack
  rescue => e
    warning "failed to remove archive files: #{e}"
  end

  def gen_ruby_upgrade_cmd_script rel_dir
    dirs = []
    files = []
    FileUtils.cd(Global::NDK_DIR) do
      File.read(File.join(rel_dir, LIST_FILE)).split("\n").each do |f|
        case
        when File.directory?(f)
          dirs << f
        when File.file?(f)
          files << f
        when !File.exist?(f)
          warning "file not exists: #{f}"
        else
          warning "strange file in file list: #{f}"
        end
      end
    end
    FileUtils.mkdir_p postpone_dir
    File.open(ruby_upgrade_script, 'w') do |f|
      f.puts '%echo off'
      f.puts 'rem This script is automatically generated to finish upgrade proccess of ruby on windows platforms'
      f.puts
      f.puts 'echo Finishing RUBY upgrade process'
      f.puts 'echo = Removing old binary files'
      f.puts
      files.sort.uniq.reverse_each do |e|
        dir = File.dirname(e)
        if (dir.end_with?('/bin') and not dir.include?('/lib/')) or (dir.end_with?('/lib') and e.end_with?('.a'))
          path = "#{Global::NDK_DIR}/#{e}".gsub('/', '\\')
          f.puts "del /f/q #{path}"
        end
      end
      f.puts
      inc_dir = dirs.select { |d| d =~ /\/include\/ruby-\d+\.\d+\.0$/ }[0]
      inc_dir = "#{Global::NDK_DIR}/#{inc_dir}".gsub('/', '\\')
      lib_dir = "#{Global::TOOLS_DIR}/lib/ruby".gsub('/', '\\')
      f.puts "echo = Removing old directories"
      f.puts "rd /q/s #{lib_dir}"
      f.puts "rd /q/s #{inc_dir}"
      f.puts
      src_dir = "#{postpone_dir}/prebuilt".gsub('/', '\\')
      dst_dir = "#{Global::NDK_DIR}/prebuilt".gsub('/', '\\')
      f.puts "echo = Coping new files"
      f.puts "xcopy #{src_dir} #{dst_dir} /e/q"
    end
  end
end
