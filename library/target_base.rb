require_relative 'shasum.rb'
require_relative 'release.rb'
require_relative 'properties.rb'
require_relative 'formula.rb'
require_relative 'build.rb'


class TargetBase < Formula

  namespace :target

  include Properties
  include MultiVersion

  BIN_PACKAGE_DIRS = ['bin', 'libs', 'libexec', 'sbin']
  DEV_PACKAGE_DIRS = ['include', 'libs']
  DEB_SKIP_DIRS    = ['src', 'tests']

  def initialize(path)
    super path

    # mark installed releases and sources
    releases.each { |r| r.update get_properties(properties_directory(r)) }

    @pre_build_result = nil
  end

  def archive_filename(release, _ = nil)
    "#{file_name}-#{release}.#{Global::ARCH_EXT}"
  end

  def cache_file(release, _ = nil)
    File.join(Global.pkg_cache_dir(self), archive_filename(release))
  end

  def deb_cache_file(release, abi)
    "#{Global::DEB_CACHE_DIR}/#{Deb.arch_for_abi(abi)}/#{Deb.file_name(name, release, abi)}"
  end

  def clean_deb_cache(release, abis)
    abis.each { |abi| FileUtils.rm_f deb_cache_file(release, abi) }
  end

  def read_shasum(release, _ = nil)
    Shasum.read qfn, release, 'android'
  end

  def update_shasum(release, _ = nil)
    archive = cache_file(release)
    Shasum.update qfn, release, 'android', Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
  end

  def copy_to_standalone_toolchain(_release, _arch, _target_include_dir, _target_lib_dir, _options)
    warning "formula #{name} does not support copying to stanalone toolchain"
  end

  def copy_to_deb_data_dir(package_dir, data_dir, abi, deb_type = :bin)
    # WARNING! We're using rsync instead of FileUtils to preserve symlinks.
    # Unfortunately, FileUtils.cp dereferences symlinks, and there is no easy way to
    # prevent it from doing it
    case deb_type
    when :bin
      bin_dir_list(package_dir).each do |dir|
        unless BIN_PACKAGE_DIRS.include? dir
          dst_dir = File.join((dir == 'share') ? "#{data_dir}/usr" : data_dir, dir)
          FileUtils.mkdir_p dst_dir
          Utils.run_command :rsync, '-a', '--delete', "#{package_dir}/#{dir}/", "#{dst_dir}/"
        else
          sub_dir = (dir == 'libs') ? 'lib' : dir
          sub_dir = "usr/#{sub_dir}" unless package_info[:root_dir].include?(dir)
          dst_dir = "#{data_dir}/#{sub_dir}"
          FileUtils.mkdir_p dst_dir
          Utils.run_command :rsync, '-a', '--delete', "#{package_dir}/#{dir}/#{abi}/", "#{dst_dir}/"
          FileUtils.rm Dir["#{dst_dir}/**/*.a"] if dir == 'libs'
        end
      end
    when :dev
      dev_dir_list(package_dir).each do |dir|
        if dir != 'libs'
          FileUtils.cp_r "#{package_dir}/#{dir}", data_dir
        else
          dst_dir = "#{data_dir}/lib"
          FileUtils.mkdir_p dst_dir
          FileUtils.cp Dir["#{package_dir}/libs/#{abi}/*.a"], dst_dir
        end
      end
    else
      raise "unsupported deb package type: #{deb_type}"
    end
  end

  def make_target_lib_dirs(arch, target_dir)
    dirs = case arch.name
           when 'arm'
             # todo: remove this when clang isssue with arm will be solved
             ["lib", "lib/thumb"] +
             ["lib/armv7-a", "lib/armv7-a/thumb", "lib/armv7-a/hard", "lib/armv7-a/thumb/hard"]
           when 'mips'
             ["lib", "libr2", "libr6"]
           when 'mips64'
             ["lib", "libr2", "libr6", "lib64", "lib64r2"]
           when 'x86_64'
             ["lib", "lib64", "libx32"]
           else
             ["lib"]
           end
    dirs << 'lib/pkgconfig'

    FileUtils.cd(target_dir) { FileUtils.mkdir_p dirs }
  end

  def build_base_dir
    "#{Build::BASE_TARGET_DIR}/#{file_name}"
  end

  def test_base_dir
    "#{Build::BASE_TARGET_DIR}/#{file_name}/test"
  end

  private

  def build_log_file
    "#{build_base_dir}/build.log"
  end

  def test_log_file
    "#{test_base_dir}/test.log"
  end

  def bin_dir_list(dir)
    Dir["#{dir}/*"].select { |d| File.directory? d }.map { |d| File.basename(d) } - ['include'] - DEB_SKIP_DIRS
  end

  def dev_dir_list(dir)
    (Dir["#{dir}/*"].select { |d| File.directory? d }.map { |d| File.basename(d) } - DEB_SKIP_DIRS) & DEV_PACKAGE_DIRS
  end
end
