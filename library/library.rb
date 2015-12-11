require_relative 'formula.rb'
require_relative 'release.rb'
require_relative 'build.rb'


class Library < Formula

  def release_directory(release)
    File.join(Global::HOLD_DIR, name, release.version)
  end

  def download_base
    "#{Global::DOWNLOAD_BASE}/packages"
  end

  def type
    :library
  end

  def install_source(release)
    puts "installing source code for #{name} #{release}"
    rel_dir = release_directory(release)
    src_dir = "#{rel_dir}/src"
    FileUtils.mkdir_p src_dir
    prop = get_properties(rel_dir)
    if prop[:crystax_version] == nil
      prop[:crystax_version] = release.crystax_version
    elsif (release.crystax_version != prop[:crystax_version])
      raise "Can't install source for release #{release}: library with crystax_version #{prop[:crystax_version]} is already installed"
    end
    install_source_code release, src_dir
    prop[:source_installed] = true
    save_properties prop, rel_dir
  end

  def build_package(release)
    raise "source code not installed for #{name} #{release}" unless release.source_installed?

    rel_dir = release_directory(release)
    src_dir = "#{rel_dir}/src"
    arch_list = Build::ARCH_LIST
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"
    pkg_dir = build(src_dir, arch_list)

    # install into packages (and update props if any)
    prop = get_properties(rel_dir)
    FileUtils.rm_rf Dir["#{rel_dir}/*"].select{ |a| File.basename(a) != 'src' }
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
  end

  private

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
end
