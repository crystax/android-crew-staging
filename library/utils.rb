require 'open3'
require 'uri'
require_relative 'global.rb'
require_relative 'exceptions.rb'

module Utils

  @@crew_curl_prog = nil
  @@crew_tar_prog  = nil

  @@patch_prog = '/usr/bin/patch'
  @@unzip_prog = '/usr/bin/unzip'


  def self.run_command(prog, *args)
    cmd = to_cmd_s(prog, *args)

    outstr = ""
    Open3.popen3(cmd) do |_, out, err, t|
      ot = Thread.start do
        while c = out.getc
          outstr += "#{c}"
        end
      end

      errstr = ""
      et = Thread.start do
        while c = err.getc
          errstr += "#{c}"
        end
      end

      ot.join
      et.join

      raise ErrorDuringExecution.new(cmd, t.value.exitstatus, errstr) unless t.value.success?
    end

    outstr
  end

  def self.download(url, outpath)
    args = [url, '-o', outpath, '--silent', '--fail', '-L']
    run_command(crew_curl_prog, *args)
  rescue ErrorDuringExecution => e
    case e.exit_code
    when 7
      raise DownloadError.new(url, e.exit_code, "failed to connect to host")
    when 22
      raise DownloadError.new(url, e.exit_code, "HTTP page not retrieved")
    else
      raise DownloadError.new(url, e.exit_code)
    end
  end

  def self.unpack(archive, outdir)
    case File.extname(archive)
    when '.zip'
      args = [archive, "-d", outdir]
      prog = unzip_prog
    else
      add_path_to_archivers
      args = ["-C", outdir, "-xf", archive]
      prog = crew_tar_prog
    end
      run_command(prog, *args)
  end

  def self.pack(archive, indir)
    FileUtils.rm archive, {force: true}
    args = ["-C", "#{indir}", "-Jcf", "#{archive}", "."]
    run_command(crew_tar_prog, *args)
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

  def self.crew_curl_prog
    @@crew_curl_prog = Pathname.new(Global.active_util_dir('curl')).realpath  + "curl#{Global::EXE_EXT}" unless @@crew_curl_prog
    @@crew_curl_prog
  end

  def self.crew_tar_prog
    @@crew_tar_prog = Pathname.new(Global.active_util_dir('libarchive')).realpath + "bsdtar#{Global::EXE_EXT}" unless @@crew_tar_prog
    @@crew_tar_prog
  end

  def self.to_cmd_s(*args)
    # todo: escape '(' and ')' too
    args.map { |a| a.to_s.gsub " ", "\\ " }.join(" ")
  end

  def self.add_path_to_archivers
    # todo: add paths to other archivers
    xz_path = Pathname.new(Global.active_util_dir('xz')).realpath.to_s
    path = ENV['PATH']
    if not path.start_with?(xz_path)
      sep = (Global::OS == 'windows') ? ';' : ':'
      ENV['PATH'] = "#{xz_path}#{sep}#{path}"
    end
  end
end
