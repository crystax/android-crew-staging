require_relative 'shasum.rb'
require_relative 'platform.rb'
require_relative 'formula.rb'

class HostBase < Formula

  include Properties
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
    #releases.each { |r| r.update get_properties(release_directory(r, Global::PLATFORM_NAME)) }
  end

  def release_directory(release, platform_name)
    File.join(Global::SERVICE_DIR, file_name, platform_name, release.version)
  end

  def upgrading_ruby?(platform_name)
    (name == 'ruby') and (Global::PLATFORM_NAME == platform_name)
  end

  def postpone_dir
    "#{Global::NDK_DIR}/postpone"
  end

  def ruby_upgrade_script
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
      if upgrading_ruby?(platform_name)
        gen_ruby_upgrade_script rel_dir
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

    target_dir = (upgrading_ruby?(platform_name) and File.exist?(ruby_upgrade_script)) ? postpone_dir : Global::NDK_DIR
    Utils.unpack archive, target_dir
    bin_list_file = File.join(target_dir, BIN_LIST_FILE)
    dev_list_file = File.join(target_dir, DEV_LIST_FILE)
    FileUtils.mv bin_list_file, rel_dir
    FileUtils.mv dev_list_file, rel_dir if File.exist? dev_list_file

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
      File.open(DEV_LIST_FILE, 'w') { |f| dev_list.each { |l| f.puts l } } unless dev_list.empty?
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

  def gen_ruby_upgrade_script rel_dir
    dirs = []
    files = []
    FileUtils.cd(Global::NDK_DIR) do
      bin_dirs, bin_files = read_files_from_list(File.join(rel_dir, BIN_LIST_FILE))
      dev_dirs, dev_files = read_files_from_list(File.join(rel_dir, DEV_LIST_FILE)) if File.exist?(DEV_LIST_FILE)
      bin_dirs  ||= []
      bin_files ||= []
      dev_dirs  ||= []
      dev_files ||= []
      dirs  = bin_dirs + dev_dirs
      files = bin_files + dev_files
    end
    FileUtils.mkdir_p postpone_dir
    File.open(ruby_upgrade_script, 'w') do |f|
      ttl = 'This script is automatically generated to finish upgrade proccess of ruby'
      if Global::OS == 'windows'
        f.puts '%echo off'
        f.puts "rem #{ttl}"
      else
        f.puts "\# #{ttl}"
      end
      f.puts
      f.puts 'echo Finishing RUBY upgrade process'
      f.puts 'echo = Removing old binary files'
      f.puts
      files.sort.uniq.reverse_each do |e|
        dir = File.dirname(e)
        if (dir.end_with?('/bin') and not dir.include?('/lib/')) or (dir.end_with?('/lib') and e.end_with?('.a'))
          path = "#{Global::NDK_DIR}/#{e}".gsub('/', '\\')
          if Global::OS != 'windows'
            f.puts "rm -f #{path}"
          else
            f.puts "del /f/q #{path}"
          end
        end
      end
      f.puts
      lib_dir = "#{Global::TOOLS_DIR}/lib/ruby"
      f.puts "echo = Removing old directories"
      if Global::OS != 'windows'
        f.puts "rm -rf #{lib_dir}"
      else
        lib_dir.gsub!('/', '\\')
        f.puts "rd /q/s #{lib_dir}"
      end
      # there can be no include dir if ruby was not installed
      inc_dir = dirs.select { |d| d =~ /\/include\/ruby-\d+\.\d+\.0$/ }[0]
      if inc_dir
        inc_dir = "#{Global::NDK_DIR}/#{inc_dir}"
        if Global::OS != 'windows'
          f.puts "rm -rf #{inc_dir}"
        else
          inc_dir.gsub!('/', '\\')
          f.puts "rd /q/s #{inc_dir}"
        end
      end
      f.puts
      f.puts "echo = Copying new files"
      src_dir = "#{postpone_dir}/prebuilt"
      if Global::OS != 'windows'
        f.puts "cp -r #{src_dir} #{Global::NDK_DIR}"
      else
        src_dir.gsub!('/', '\\')
        dst_dir = "#{Global::NDK_DIR}/prebuilt".gsub('/', '\\')
        f.puts "xcopy #{src_dir} #{dst_dir} /e/q"
      end
    end
    FileUtils.chmod 'a+x', ruby_upgrade_script
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
end
