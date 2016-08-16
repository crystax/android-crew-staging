require 'open3'
require 'uri'
require_relative 'global.rb'
require_relative 'exceptions.rb'

module Utils

  @@curl_prog = nil
  @@tar_prog  = nil

  @@patch_prog = '/usr/bin/patch'
  @@unzip_prog = '/usr/bin/unzip'


  def self.run_command(prog, *args)
    cmd = ([prog.to_s] + args).map { |e| to_cmd_s(e) }
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
    # todo: use crew's own patch program?
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
    @@tar_prog = Pathname.new(Utility.active_dir('libarchive')).realpath + "bsdtar#{Global::EXE_EXT}" unless @@tar_prog
    @@tar_prog
  rescue
    # todo: output warning?
    @@tar_prog = 'tar'
  end

  def self.reset_tar_prog
    @@tar_prog = nil
  end

  def self.to_cmd_s(*args)
    # todo: escape '(' and ')' too
    args.map { |a| a.to_s.gsub " ", "\\ " }.join(" ")
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
