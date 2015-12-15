require 'uri'
require 'tmpdir'
require 'fileutils'
require_relative 'formula.rb'
require_relative 'release.rb'
require_relative 'build.rb'


class Library < Formula

  SRC_DIR_BASENAME = 'src'

  def release_directory(release)
    File.join(Global::HOLD_DIR, name, release.version)
  end

  def download_base
    "#{Global::DOWNLOAD_BASE}/packages"
  end

  def type
    :library
  end

  def uninstall(version)
    puts "removing #{name}-#{version}"
    rel_dir = release_directory(Release.new(version))
    props = get_properties(rel_dir)
    if not props[:source_installed]
      FileUtils.rm_rf dir
    else
      FileUtils.rm_rf binary_files(rel_dir)
      props[:installed] = false
      save_properties prop, rel_dir
    end
    releases.each do |r|
      if (r.version == version) and (r.crystax_version == props[:crystax_version])
        r.installed = false
        break
      end
    end
  end

  def install_source(release)
    puts "installing source code for #{name}:#{release}"
    rel_dir = release_directory(release)
    prop = get_properties(rel_dir)
    if prop[:crystax_version] == nil
      prop[:crystax_version] = release.crystax_version
      FileUtils.mkdir_p rel_dir
    end

    ver_url = version_url(release.version)
    archive = "#{Global::CACHE_DIR}/#{File.basename(URI.parse(ver_url).path)}"
    if File.exists? archive
      puts "= using cached file #{archive}"
    else
      puts "= downloading #{ver_url}"
      Utils.download(ver_url, archive)
    end

    # todo: handle option source_archive_without_top_dir: true
    old_dir = Dir["#{rel_dir}/*"]
    puts "= unpacking #{File.basename(archive)} into #{rel_dir}"
    Utils.unpack(archive, rel_dir)
    new_dir = Dir["#{rel_dir}/*"]
    diff = old_dir.count == 0 ? new_dir : new_dir - old_dir
    raise "source archive does not have top directory, diff: #{diff}" if diff.count != 1
    FileUtils.cd(rel_dir) { FileUtils.mv diff[0], SRC_DIR_BASENAME }

    prop[:source_installed] = true
    save_properties prop, rel_dir
  end

  def build_package(release)
    rel_dir = release_directory(release)
    src_dir = "#{rel_dir}/#{SRC_DIR_BASENAME}"
    arch_list = Build::ARCH_LIST
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"
    pkg_dir = build(src_dir, arch_list)

    # pack archive and copy into cache dir
    archive = "#{Build::CACHE_DIR}/#{archive_filename(release)}"
    puts "Creating archive file #{archive}"
    Utils.pack(archive, pkg_dir)

    # install into packages (and update props if any)
    puts "Unpacking archive into #{release_dir(release)}"
    install_release_archive release, archive

    # calculate and update shasum
    # todo:

    # cleanup
    # todo:
  end

  private

  def version_url(version)
    url.gsub('{version}', version)
  end

  def archive_filename(release)
    "#{name}-#{Formula.package_version(release)}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(:android)
  end

  def install_archive(release, archive)
    rel_dir = release_directory(release)
    FileUtils.rm_rf binary_files(rel_dir)
    Utils.unpack archive, rel_dir
    update_root_android_mk release
  end

  def binary_files(rel_dir)
    Dir["#{rel_dir}/*"].select{ |a| File.basename(a) != SRC_DIR_BASENAME }
  end

  # $(call import-module,libjpeg/9a)
  def update_root_android_mk(release)
    android_mk = "#{File.dirname(release_directory(release))}/Android.mk"
    new_ver = release.version
    if not File.exists? android_mk
      write_root_android_mk android_mk, new_ver
    else
      prev_ver = File.read(android_mk).strip.delete("()").split('/')[1]
      new_ver = release.version
      if more_recent_version(prev_ver, new_ver) == new_ver
        write_root_android_mk android_mk, new_ver
      end
    end
  end

  def write_android_mk(file, ver)
    File.open(file, 'w') { |f| f.puts "include $(call my-dir)/#{ver}/Android.mk" }
  end
end
