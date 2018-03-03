module Deb

  FORMAT_VERSION     = '2.0'
  DEBIAN_BINARY_FILE = 'debian-binary'
  CONTROL_TAR_FILE   = 'control.tar.xz'
  DATA_TAR_FILE      = 'data.tar.xz'


  def self.make_bin_package(package_dir, working_dir, abi, root_prefix, formula, release)
    FileUtils.cd(working_dir) do
      make_debian_binary_file
      make_data_tar_file    formula, release, :bin, root_prefix, abi, package_dir
      make_control_tar_file formula, release, :bin, root_prefix, abi
      make_deb_file "#{formula.name}_#{release}_#{arch_for_abi(abi)}.deb"
    end
  end

  def self.arch_for_abi(abi)
    case abi
    when 'armeabi-v7a'
      'armel'
    when 'armeabi-v7a-hard'
      'armhf'
    when 'x86'
      'i386'
    when 'mips'
      'mipsel'
    when 'arm64-v8a'
      'arm64'
    when 'x86_64'
      'amd64'
    when 'mips64'
      'mips64el'
    else
      raise "unsupported abi for make deb: #{abi}"
    end
  end

  def self.make_debian_binary_file
    File.open(DEBIAN_BINARY_FILE, 'w') { |f| f.puts FORMAT_VERSION }
  end

  def self.make_data_tar_file(formula, release, deb_type, data_dir, abi, package_dir)
    FileUtils.mkdir_p data_dir
    formula.copy_to_deb_data_dir package_dir, data_dir, abi, deb_type
    pack_archive '.', DATA_TAR_FILE, data_dir.split('/')[0]
  end

  def self.make_control_tar_file(formula, release, deb_type, data_dir, abi)
    control_dir = 'control'
    FileUtils.mkdir_p control_dir

    installed_size = Dir.size(data_dir) / 1024
    deps = formula.dependencies.map { |d| d.name }

    File.open("#{control_dir}/control", 'w') do |f|
      f.puts "Package: #{formula.name}"
      f.puts "Version: #{release}"
      f.puts "Description: #{formula.desc}"
      f.puts "Priority: standard"              # todo: deb_info[:priority] ? deb_info[:priority] : 'standard',
      f.puts "Installed-size: #{installed_size}"
      f.puts "Architecture: #{arch_for_abi(abi)}"
      f.puts "Homepage: #{formula.homepage}"
      f.puts "Depends: #{deps.join(', ')}" unless deps.empty?
    end

    pack_archive control_dir, CONTROL_TAR_FILE, Dir["#{control_dir}/*"].map { |f| File.basename(f) }
  end

  def self.make_deb_file(archive)
    args = ['q', archive, DEBIAN_BINARY_FILE, CONTROL_TAR_FILE, DATA_TAR_FILE]
    Utils.run_command Utils.crew_ar_prog, *args
  end

  def self.pack_archive(dir, archive, files)
    args = ['--format', 'ustar', '-C', dir, '-Jcf', archive, files].flatten
    Utils.run_command Utils.crew_tar_prog, *args
  end
end
