require_relative 'shasum.rb'
require_relative 'platform.rb'
require_relative 'formula.rb'


class HostBase < Formula

  include SingleVersion

  namespace :host

  BIN_LIST_FILE = 'list'
  DEV_LIST_FILE = 'list-dev'

  def initialize(path)
    super path

    # todo: handle platform dependant installations
    # mark installed releases and sources
    base_dir = File.join(Global::SERVICE_DIR, file_name, Global::PLATFORM_NAME)
    Dir.exist?(base_dir) and FileUtils.cd(base_dir) do
      Dir['*'].each do |ver|
        props = get_properties(ver)
        ind = releases.find_index { |r| r.version == ver }
        if ind
          releases[ind].update props
        else
          r = Release.new(ver, props[:installed_crystax_version])
          r.update props
          r.obsolete = true
          releases.unshift r
        end
      end
    end
  end

  def release_directory(release, platform_name)
    File.join(Global::SERVICE_DIR, file_name, platform_name, release.version)
  end

  def support_dev_files?
    true
  end

  def dev_files_installed?(_release, _platform_name = Global::PLATFORM_NAME)
    raise "'#{name} has no dev files" unless has_dev_files?
    false
  end

  # def upgrading_ruby?(platform_name)
  #   (name == 'ruby') and (Global::PLATFORM_NAME == platform_name)
  # end

  # def upgrading_xz?(platform_name)
  #   (name == 'xz') and (Global::PLATFORM_NAME == platform_name)
  # end

  # def upgrading_tar?(platform_name)
  #   (name == 'tar') and (Global::PLATFORM_NAME == platform_name)
  # end

  def postpone_dir
    "#{Global::NDK_DIR}/postpone"
  end

  def upgrade_script_filename
    ext = Global::OS == 'windows' ? 'cmd' :  'sh'
    "#{postpone_dir}/upgrade.#{ext}"
  end

  def install(release = releases.last, opts = {})
    options = merge_default_install_options(opts)

    super release, options

    platform_name = options[:platform]
    dev_file_list = File.join(release_directory(release, platform_name), DEV_LIST_FILE)

    unless options[:with_dev_files]
      if File.exist? dev_file_list
        remove_files_from_list dev_file_list, platform_name
        FileUtils.rm dev_file_list
      end
    end
  end

  def uninstall_archive(release, platform_name)
    rel_dir = release_directory(release, platform_name)
    if Dir.exist? rel_dir
      if postpone_install?(platform_name)
        update_upgrade_script rel_dir
      else
        remove_archive_files rel_dir, platform_name
      end
      FileUtils.rm_rf rel_dir
    end
  end

  def install_archive(release, archive, platform_name)
    # todo: handle multi platform
    #       add platform support into Release class
    prev_release = releases.select { |r| r.installed? }.last
    uninstall_archive prev_release, platform_name if prev_release

    rel_dir = release_directory(release, platform_name)
    FileUtils.mkdir_p rel_dir

    target_dir = postpone_install?(platform_name) ? postpone_dir : Global::NDK_DIR

    Utils.unpack archive, target_dir

    bin_list_file = File.join(target_dir, BIN_LIST_FILE)
    dev_list_file = File.join(target_dir, DEV_LIST_FILE)
    FileUtils.mv bin_list_file, rel_dir
    FileUtils.mv dev_list_file, rel_dir if File.exist? dev_list_file

    if postpone_install?(platform_name)
      prop_file = File.join(target_dir, release_dir_suffix(release, platform_name), Properties::FILE)
      FileUtils.mv prop_file, rel_dir
    end

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
      bin_list, dev_list = split_file_list(list, platform_name)
      File.open(BIN_LIST_FILE, 'w') { |f| bin_list.each { |l| f.puts l } }
      unless dev_list.empty?
        raise "'#{name}' is not supposed to have dev files: #{dev_list.join(',')}" unless has_dev_files?
        File.open(DEV_LIST_FILE, 'w') { |f| dev_list.each { |l| f.puts l } }
      end
    end
  end

  # default implementation
  def split_file_list(list, _platform_name)
    [list, []]
  end

  def remove_archive_files(rel_dir, platform_name)
    bin_list_file = File.join(rel_dir, BIN_LIST_FILE)
    dev_list_file = File.join(rel_dir, DEV_LIST_FILE)
    remove_files_from_list(bin_list_file, platform_name)
    remove_files_from_list(dev_list_file, platform_name) if File.exist? dev_list_file
  end

  def update_upgrade_script rel_dir
    unless File.exist? upgrade_script_filename
      FileUtils.mkdir_p File.dirname(upgrade_script_filename)
      File.open(upgrade_script_filename, 'w') do |f|
        ttl = 'This script is automatically generated to finish upgrade proccess of ruby'
        if Global::OS != 'windows'
          f.puts "\# #{ttl}"
        else
          f.puts '%echo off'
          f.puts "rem #{ttl}"
        end
      end
    end

    dirs = []
    files = []
    FileUtils.cd(Global::NDK_DIR) do
      dirs, files = read_files_from_list(File.join(rel_dir, BIN_LIST_FILE))
      if File.exist?(DEV_LIST_FILE)
        dev_dirs, dev_files = read_files_from_list(File.join(rel_dir, DEV_LIST_FILE))
        dirs  += dev_dirs
        files += dev_files
      end
    end

    FileUtils.mkdir_p postpone_dir
    File.open(upgrade_script_filename, 'a') do |f|
      f.puts
      f.puts "echo Finishing #{name.upcase} upgrade process"
      f.puts 'echo = Removing old binary files'
      f.puts
      files.sort.uniq.each do |file|
        path = "#{Global::NDK_DIR}/#{file}"
        if Global::OS != 'windows'
          f.puts "rm -f #{path}"
        else
          f.puts "del /f/q #{path.gsub('/', '\\')}"
        end
      end
      f.puts

      f.puts "echo = Removing old directories"
      dirs.sort.uniq.reverse_each do |dir|
        if Dir.empty? dir
          path = "#{Global::NDK_DIR}/#{dir}"
          if Global::OS != 'windows'
            f.puts "rmdir #{path}"
          else
            f.puts "rmdir #{path.gsub('/', '\\')}"
          end
        end
      end

      # f.puts
      # f.puts "echo = Copying new files"
      # src_dir = "#{postpone_dir}/prebuilt"
      # if Global::OS != 'windows'
      #   f.puts "cp -r #{src_dir} #{Global::NDK_DIR}"
      # else
      #   src_dir.gsub!('/', '\\')
      #   dst_dir = "#{Global::NDK_DIR}/prebuilt".gsub('/', '\\')
      #   f.puts "xcopy #{src_dir} #{dst_dir} /e/q"
      # end
    end
    FileUtils.chmod 'a+x', upgrade_script_filename
  end

  def remove_files_from_list(file_list, platform_name)
    FileUtils.cd(Global::NDK_DIR) do
      files = []
      dirs = []
      File.read(file_list).split("\n").each do |f|
        case
        when File.symlink?(f)
          files << f
        when File.directory?(f)
          dirs << f
        when File.file?(f)
          files << f
        when !File.exist?(f)
          warning "#{name}, #{platform_name}: file not exists: #{f}"
        else
          raise "#{name}, #{platform_name}: strange file in file list: #{f}"
        end
      end
      files.sort.uniq.each { |f| FileUtils.rm_f f }
      dirs.sort.uniq.reverse_each { |d| FileUtils.rmdir(d) if Dir.empty?(d) }
    end
  end

  def read_files_from_list(file_list)
    dirs = []
    files = []
    File.read(file_list).split("\n").each do |f|
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

    [dirs, files]
  end

  # generic implementation to be used by utilities that are libraries like zlib, openssl
  def split_file_list_by_shared_libs(list, platform_name)
    # put binary files to bin list
    bin_list, dev_list = list.partition { |e| e =~ /(bin\/.+)|(lib\/.*\.(so|so\..+|dylib))/ }
    # add directories to bin list
    dirs = []
    bin_list.each do |f|
      ds = File.dirname(f).split('/')
      dirs += (1..ds.size).map { |e| ds.first(e).join('/') }
    end
    bin_list += dirs.sort.uniq

    [bin_list.sort, dev_list.sort]
  end

  # generic implementation to be used by utilities that are have binaries like xz
  def split_file_list_by_static_libs_and_includes(list, platform_name)
    dev_list, bin_list = list.partition { |e| e =~ /(.*\.h)|(.*\.a)$/ }
    bin_list = bin_list.select { |e| not File.directory?(e) }

    [bin_list, dev_list].each do |l|
      dirs = []
      l.each do |f|
        ds = File.dirname(f).split('/')
        dirs += (1..ds.size).map { |e| ds.first(e).join('/') }
      end
      l << dirs.sort.uniq
      l.flatten!
    end

    [bin_list.sort, dev_list.sort]
  end

  def clean_install_dir(platform_name, release, *types)
    FileUtils.cd(install_dir_for_platform(platform_name, release)) do
      types.each do |type|
        case type
        when :lib
          FileUtils.rm_rf ['lib/pkgconfig'] + Dir['lib/**/*.la']
        when :share
          FileUtils.rm_rf 'share'
        else
          raise "unknown type to cleanup: #{type}"
        end
      end
    end
  end

  def build_info_install_dir(platform_name, release)
    File.join(base_dir_for_platform(platform_name), release_dir_suffix(release, platform_name))
  end

  def write_build_info(platform_name, release)
    dir = build_info_install_dir(platform_name, release)
    prop = { build_info: @host_build_info + @target_build_info }
    save_properties prop, dir
  end

  def release_dir_suffix(release, platform_name)
    s = release_directory(release, platform_name).delete_prefix(File.dirname(Global::SERVICE_DIR))
    s = s[1..-1] if s.start_with?('/')
    s
  end
end
