require_relative 'platform.rb'
require_relative 'formula.rb'

class HostFormula < Formula

  namespace :host

  def archive_filename(release, platform_name = Global::PLATFORM_NAME)
    "#{file_name}-#{release}-#{platform_name}.tar.xz"
  end

  def cache_file(release, plaform_name)
    File.join(Global::PKG_CACHE_DIR, archive_filename(release, plaform_name))
  end

  def build_base_dir
    File.join Build::BASE_HOST_DIR, file_name
  end

  def src_dir
    File.join build_base_dir, 'src'
  end

  def base_dir_for_platform(platform)
    File.join build_base_dir, platform.name
  end

  def build_dir_for_platform(platform)
    File.join base_dir_for_platform(platform), 'build'
  end

  def build_log_file(platform)
    File.join base_dir_for_platform(platform), 'build.log'
  end

  def sha256_sum(release)
    release.shasum(Global::PLATFORM_NAME.gsub(/-/, '_').to_sym)
  end

  def update_shasum(release, platform)
    ver = release.version
    cxver = release.crystax_version
    sum = release.shasum(platform.to_sym)
    release_regexp = /^[[:space:]]*release[[:space:]]+version:[[:space:]]+'#{ver}',[[:space:]]+crystax_version:[[:space:]]+#{cxver}/
    platform_regexp = /#{platform.to_sym}:/
    lines = []
    state = :copy
    File.foreach(path) do |l|
      case state
      when :updated
        lines << l
      when :copy
        if  l !~ release_regexp
          lines << l
        else
          if l !~ platform_regexp
            state = :updating
            lines << l
          else
            state = :updated
            lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
          end
        end
      when :updating
        if l !~ platform_regexp
          lines << l
        else
          state = :updated
          lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
        end
      else
        raise "in formula #{File.basename(file_name)} bad state #{state} on line: #{l}"
      end
    end

    File.open(path, 'w') { |f| f.puts lines }
  end
end
