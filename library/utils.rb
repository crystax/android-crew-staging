require 'open3'
require 'uri'
require 'rugged'
require_relative 'global.rb'
require_relative 'exceptions.rb'

module Utils

  @@curl_prog = nil
  @@tar_prog  = nil

  @@crew_tar_prog      = File.join(Global::TOOLS_DIR, 'bin', "bsdtar#{Global::EXE_EXT}")
  @@crew_copy_tar_prog = File.join(Global::TOOLS_DIR, 'bin', "bsdtar-copy#{Global::EXE_EXT}")

  @@patch_prog = '/usr/bin/patch'
  @@unzip_prog = '/usr/bin/unzip'

  # returns [file_name, release_str, platform_name]
  # for target archives platform will be 'android'
  def self.split_archive_path(path)
    raise "unssupported archive type: #{path}" unless path.end_with? Global::ARCH_EXT

    type_dir = File.basename(File.dirname(path))
    filename = File.basename(path, ".#{Global::ARCH_EXT}")

    case type_dir
    when Global::NS_DIR[:target]
      platform_name = 'android'
      arr = filename.split('-')
      raise "bad package filename #{filename}" if arr.size < 2
      name = arr[0]
      release_str = arr.drop(1).join('-')
    when Global::NS_DIR[:host]
      arr = filename.split('-')
      raise "bad tool filename #{filename}" if arr.size < 3
      name = arr[0]
      arr = arr.drop(1)
      platform_name = arr.pop
      platform_name = "#{arr.pop}-#{platform_name}" if platform_name == 'x86_64'
      release_str = arr.join('-')
    else
      raise "bad package cache archive type: #{type_dir}"
    end

    [name, release_str, platform_name]
  end

  def self.split_package_version(pkgver)
    r = pkgver.split('_')
    raise "bad package version string: #{pkgver}" if r.size < 2
    cxver = r.pop.to_i
    ver = r.join('_')
    [ver, cxver]
  end

  def self.run_command(prog, *args)
    cmd = ([prog.to_s.strip] + args).map { |e| to_cmd_s(e) }
    #puts "cmd: #{cmd.join(' ')}"
    outstr, errstr, status = Open3.capture3(*cmd)
    raise ErrorDuringExecution.new(cmd.join(' '), status.exitstatus, errstr) unless status.success?

    outstr
  end

  def self.download(url, outpath)
    args = [url, '-o', outpath, '--silent', '--fail', '-L']
    run_command(curl_prog, *args)
  rescue ErrorDuringExecution => e
    case e.exit_code
    when 7
      raise DownloadError.new(url, e.exit_code, "failed to connect to host")
    when 22
      raise DownloadError.new(url, e.exit_code, "HTTP page not retrieved")
    else
      raise
    end
  end

  def self.unpack(archive, outdir)
    FileUtils.mkdir_p outdir unless Dir.exists? outdir
    case File.extname(archive)
    when '.zip'
      args = [archive, "-d", outdir]
      prog = unzip_prog
    else
      # todo: remove
      #add_path_to_archivers
      args = ["-C", outdir, "-xf", archive]
      prog = tar_prog
    end
      run_command(prog, *args)
  end

  def self.pack(archive, indir, *dirs)
    FileUtils.rm_f archive
    FileUtils.mkdir_p File.dirname(archive)
    dirs << '.' if dirs.empty?
    args = ['-C', indir, '-Jcf', archive] + dirs
    run_command(tar_prog, *args)
  end

  def self.processor_count
    case Global::OS
    when /darwin/
      `sysctl -n hw.ncpu`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    else
      raise "this OS (#{Global::OS}) is not supported to count processors"
    end
  end

  def self.patch_prog
    # todo: use crew's own patch program?
    @@patch_prog
  end

  def self.unzip_prog
    # todo: use crew's own unzip program?
    @@unzip_prog
  end

  # private

  def self.curl_prog
    @@curl_prog = Pathname.new(Utility.active_dir('curl')).realpath  + "curl#{Global::EXE_EXT}" unless @@curl_prog
    @@curl_prog
  rescue
    # todo: output warning?
    @@curl_prog = 'curl'
  end

  def self.tar_prog
    @@tar_prog = File.exist?(@@crew_tar_prog) ? @@crew_tar_prog : 'tar' unless @@tar_prog
    @@tar_prog
  end

  def self.use_copy_tar_prog
    if not File.exist? @@crew_tar_prog
      @@tar_prog = nil
    else
      FileUtils.cp @@crew_tar_prog, @@crew_copy_tar_prog
      @@tar_prog = @@crew_copy_tar_prog
    end
  end

  def self.reset_tar_prog
    @@tar_prog = nil
    FileUtils.rm_f @@crew_copy_tar_prog
  end

  def self.to_cmd_s(*args)
    # todo: escape '(' and ')' too
    args.map { |a| a.to_s.gsub " ", "\\ " }.join(" ")
  end

  def self.make_git_credentials(url)
    case url
    when /github\.com/
      # no credentials for github based repos
      nil
    when /git@git\.crystax\.net/
        Rugged::Credentials::SshKey.new(username: 'git',
                                        publickey: File.expand_path("~/.ssh/id_rsa.pub"),
                                        privatekey: File.expand_path("~/.ssh/id_rsa"))
    when /https:\/\/git\.crystax\.net/
      # when we run on the CI machine GITLAB_USERNAME and GITLAB_PASSWORD env vars must be set
      unless [nil, ''].include? ENV['GITLAB_USERNAME']
        Rugged::Credentials::UserPassword.new(username: ENV['GITLAB_USERNAME'], password: ENV['GITLAB_PASSWORD'])
      else
        nil
      end
    else
      nil
    end
  end

  # todo: remove
  # def self.add_path_to_archivers
  #   # todo: add paths to other archivers
  #   xz_path = Pathname.new(Global.active_util_dir('xz')).realpath.to_s
  #   path = ENV['PATH']
  #   if not path.start_with?(xz_path)
  #     sep = (Global::OS == 'windows') ? ';' : ':'
  #     ENV['PATH'] = "#{xz_path}#{sep}#{path}"
  #   end
  # end
end
