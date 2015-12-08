require_relative 'formula.rb'
require_relative 'release.rb'


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
