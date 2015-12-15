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
    install_source_code release, SRC_DIR_BASENAME
    prop[:source_installed] = true
    save_properties prop, rel_dir
  end

  def build_package(release)
    rel_dir = release_directory(release)
    src_dir = "#{rel_dir}/#{SRC_DIR_BASENAME}"
    arch_list = Build::ARCH_LIST
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"
    pkg_dir = build(src_dir, arch_list)

    # install into packages (and update props if any)
    prop = get_properties(rel_dir)
    FileUtils.rm_rf binary_files(rel_dir)
    FileUtils.cp_r "#{pkg_dir}/.", rel_dir
    prop.update get_properties(rel_dir)
    prop[:installed] = true
    release.installed = true
    save_properties prop, rel_dir

    # pack archive and copy into cache dir
    archive = "#{Build::CACHE_DIR}/#{archive_filename(release)}"
    Utils.pack(archive, pkg_dir)

    # calculate and update shasum
    # todo:

    # cleanup
    # todo:
  end

  private

  def std_download_source_code(url, rel_dir, vername, dirname)
    Dir.mktmpdir do |tmpdir|
      archive = "#{tmpdir}/#{File.basename(URI.parse(url).path)}"
      puts "= downloading #{url}"
      Utils.download(url, archive)
      puts "= unpacking #{File.basename(archive)} into #{rel_dir}/#{dirname}"
      Utils.unpack(archive, rel_dir)
      FileUtils.cd(rel_dir) { FileUtils.mv vername, dirname }
    end
  end

  def archive_filename(release)
    "#{name}-#{Formula.package_version(release)}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(:android)
  end

  def install_archive(outdir, archive)
    FileUtils.rm_rf outdir
    FileUtils.mkdir_p outdir
    Utils.unpack(archive, outdir)
  end

  def binary_files(rel_dir)
    Dir["#{rel_dir}/*"].select{ |a| File.basename(a) != SRC_DIR_BASENAME }
  end
end
