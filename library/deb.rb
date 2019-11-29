module Deb

  FORMAT_VERSION     = '2.0'
  DEBIAN_BINARY_FILE = 'debian-binary'
  CONTROL_FILE       = 'control'
  CONTROL_TAR_FILE   = 'control.tar.xz'
  DATA_TAR_FILE      = 'data.tar.xz'


  def self.make_bin_package(package_dir, working_dir, abi, repo_base, formula, release)
    archive_dir = "#{repo_base}/#{arch_for_abi(abi)}"
    data_dir = "#{working_dir}/data"
    FileUtils.mkdir_p [archive_dir, data_dir]
    FileUtils.cd(working_dir) do
      make_debian_binary_file
      make_data_tar_file    formula, release, :bin, abi, data_dir, package_dir
      make_control_tar_file formula, release, :bin, abi, data_dir
      make_deb_file "#{archive_dir}/#{file_name(formula.name, release, abi)}"
    end
  end

  def self.install_deb_archive(formula, dst_dir, archive, abi)
    arch = arch_for_abi(abi)
    src_dir = "#{Build::BASE_TARGET_DIR}/tmp"
    FileUtils.rm_rf src_dir
    FileUtils.mkdir_p src_dir

    FileUtils.cd(src_dir) do
      Utils.run_command Utils.crew_ar_prog, '-x', archive

      data_dir = 'data'
      FileUtils.mkdir_p data_dir
      unpack_archive data_dir, DATA_TAR_FILE
      FileUtils.cp_r Dir["#{data_dir}/*"], dst_dir

      dpkg_dir = "#{dst_dir}/var/lib/dpkg"
      FileUtils.mkdir_p dpkg_dir
      unpack_archive '.', CONTROL_TAR_FILE
      status_info = File.readlines(CONTROL_FILE)
      status_info.insert(1, "Status: install ok installed\n")
      status_info << "\n"
      status_file = "#{dpkg_dir}/status"
      File.open(status_file, 'a') { |f| f.puts(status_info) }

      arch_file = "#{dpkg_dir}/arch"
      File.open(arch_file, 'w') { |f| f.puts arch } unless File.exist? arch_file

      info_dir = "#{dpkg_dir}/info"
      FileUtils.mkdir_p info_dir
      make_m5sums_file data_dir, "#{info_dir}/#{formula.name}.md5sums"
      make_list_file   data_dir, "#{info_dir}/#{formula.name}.list"
    end
  end

  def self.file_name(name, release, abi)
    "#{name}_#{version(release)}_#{arch_for_abi(abi)}.deb"
  end

  def self.version(release)
    "#{release.version}-#{release.crystax_version}"
  end

  def self.arch_for_abi(abi)
    case abi
    when 'armeabi-v7a'
      'armel'
    when 'armeabi-v7a-hard'
      'armhf'
    when 'x86'
      'i386'
    when 'arm64-v8a'
      'arm64'
    when 'x86_64'
      'amd64'
    else
      raise "unsupported abi for make deb: #{abi}"
    end
  end

  def self.make_debian_binary_file
    File.open(DEBIAN_BINARY_FILE, 'w') { |f| f.puts FORMAT_VERSION }
  end

  def self.make_data_tar_file(formula, release, deb_type, abi, data_dir, package_dir)
    formula.copy_to_deb_data_dir package_dir, data_dir, abi, deb_type
    pack_archive data_dir, DATA_TAR_FILE, '.'
  end

  def self.make_control_tar_file(formula, release, deb_type, abi, data_dir)
    control_dir = 'control'
    FileUtils.mkdir_p control_dir

    installed_size = Dir.size(data_dir) / 1024
    deps = formula.dependencies.map { |d| d.name }

    File.open("#{control_dir}/control", 'w') do |f|
      f.puts "Package: #{formula.name}"
      f.puts "Version: #{version(release)}"
      f.puts "Description: #{formula.desc}"
      f.puts "Priority: standard"                             # todo: deb_info[:priority] ? deb_info[:priority] : 'standard',
      f.puts "Installed-size: #{installed_size}"
      f.puts "Maintainer: Alexander Zhukov <zuav@crystax.net>"
      f.puts "Architecture: #{arch_for_abi(abi)}"
      f.puts "Homepage: #{formula.homepage}"
      f.puts "Depends: #{deps.join(', ')}" unless deps.empty?
    end

    pack_archive control_dir, CONTROL_TAR_FILE, Dir["#{control_dir}/*"].map { |f| File.basename(f) }
  end

  def self.make_deb_file(archive)
    FileUtils.rm_rf archive
    args = ['q', archive, DEBIAN_BINARY_FILE, CONTROL_TAR_FILE, DATA_TAR_FILE]
    Utils.run_command Utils.crew_ar_prog, *args
  end

  def self.pack_archive(dir, archive, files)
    args = ['--format', 'ustar', '-C', dir, '-Jcf', archive, files].flatten
    Utils.run_command Utils.crew_tar_prog, *args
  end

  def self.unpack_archive(dir, archive)
    args = ['-C', dir, '-xf', archive]
    Utils.run_command Utils.crew_tar_prog, *args
  end

  def self.make_m5sums_file(dir, sums_file)
    FileUtils.cd(dir) do
      File.open(sums_file, 'w') do |f|
        Dir['./**/*'].select { |f| File.file?(f) }.each do |file|
          f.puts Utils.run_md5sum(file)
        end
      end
    end
  end

  def self.make_list_file(dir, list_file)
    FileUtils.cd(dir) do
      files = Dir['./**/*'].map { |l| l.sub(/^\./, '') }
      File.open(list_file, 'w') { |f| f.puts files.join("\n") }
    end
  end
end
