require 'open3'
require 'uri'
require 'rugged'
require 'tempfile'
require 'minitar'
require_relative 'global.rb'
require_relative 'exceptions.rb'

module Utils

  @@curl_prog = nil
  @@tar_prog  = nil
  @@xz_prog   = nil

  @@crew_ar_prog       = File.join(Global::TOOLS_DIR, 'bin', "ar#{Global::EXE_EXT}")
  @@crew_tar_prog      = File.join(Global::TOOLS_DIR, 'bin', "bsdtar#{Global::EXE_EXT}")
  @@crew_tar_copy_prog = File.join(Global::TOOLS_DIR, 'bin', "bsdtar-copy#{Global::EXE_EXT}")
  @@crew_xz_prog       = File.join(Global::TOOLS_DIR, 'bin', "xz#{Global::EXE_EXT}")
  @@crew_xz_copy_prog  = File.join(Global::TOOLS_DIR, 'bin', "xz-copy#{Global::EXE_EXT}")

  @@patch_prog  = '/usr/bin/patch'
  @@unzip_prog  = '/usr/bin/unzip'
  @@md5sum_prog = (Global::OS == 'darwin') ? '/usr/local/bin/md5sum' : '/usr/bin/md5sum'

  @@system_curl = 'curl'
  @@system_tar  = 'tar'

  # returns [file_name, release_str, platform_name]
  # for target archives platform will be 'android'
  def self.split_archive_path(path)
    raise "unsupported archive type: #{path}" unless path.end_with? Global::ARCH_EXT

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
    prog = prog.to_s.strip
    cmd = ([prog] + args).map { |e| to_cmd_s(e) }
    env = {}
    if prog == @@system_curl
      case Global::OS
      when 'linux'
        env['LD_LIBRARY_PATH'] = nil
      when 'darwin'
        env['DYLD_LIBRARY_PATH'] = nil
      end
    end
    #puts "cmd: #{cmd.join(' ')}"
    #puts "env: #{env}"
    outstr, errstr, status = Open3.capture3(env, *cmd)
    raise ErrorDuringExecution.new(cmd.join(' '), status.exitstatus, errstr) unless status.success?

    outstr
  end

  def self.run_md5sum(*args)
    run_command @@md5sum_prog, *args
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
      run_command unzip_prog, archive, "-d", outdir
    when '.xz'
      # we use our custom untar to handle symlinks in crew's own archives on windows;
      # since we do not support building crew packages on windows hosts
      # we do not care about symlinks in other archive types (gz, bz2, etc)
      if (Global::OS == 'windows')
        untar archive, outdir, dereference: true
      else
        run_command tar_prog, "-C", outdir, "-xf", archive
      end
    else
      run_command tar_prog, "-C", outdir, "-xf", archive
    end
  end

  def self.untar(file, to_dir, options)
    tempfile = Tempfile.new([File.basename(file), '.tar'])

    begin
      tempfile.close
      tar_file = tempfile.path
      xz_cmd = "#{xz_prog} -dc #{file} > #{tar_file}"
      `#{xz_cmd}`
      raise "xz failed: #{xz_cmd}" unless $? == 0
      File.open(tar_file, 'r') do |f|
        f.set_encoding Encoding::ASCII_8BIT
        Minitar::Reader.open(f) do |tar|
          entries = []
          symlinks = {}
          tar.each do |entry|

            class << entry
              def symlink?
                typeflag == '2'
              end
              alias symlink symlink?
            end

            dst = File.join(to_dir, entry.full_name)
            FileUtils.mkdir_p File.dirname(dst)

            if entry.directory?
              FileUtils.mkdir_p dst
            elsif entry.file?
              File.open(dst, 'wb') do |wf|
                wf.set_encoding Encoding::ASCII_8BIT
                while buf = entry.read(4194304)
                  wf.write buf
                end
              end
            elsif entry.symlink?
              if options[:dereference]
                symlinks[dst] = entry.linkname
              else
                FileUtils.rm_f dst
                FileUtils.ln_s entry.linkname, dst
              end
            else
              raise "unsupported tar entry: #{entry.inspect}"
            end

            if File.exists?(dst)
              FileUtils.chmod entry.mode, dst
            end

            entries << dst
          end

          while !symlinks.empty?
            old_size = symlinks.size
            symlinks.keys.each do |dst|
              linkname = symlinks[dst]
              src = File.expand_path(linkname, File.dirname(dst))

              next unless File.exists?(src)

              FileUtils.rm_f dst
              FileUtils.mkdir_p File.dirname(dst)
              src = File.expand_path(linkname, File.dirname(dst))
              FileUtils.cp_r src, dst

              stat = File.stat(src)
              FileUtils.chmod stat.mode, dst

              symlinks.delete(dst)
            end

            raise "tar file has dangling symlinks and --derefence options was specified: #{hash}" if old_size == symlinks.size
          end
        end
      end
    ensure
      tempfile.unlink
    end
  end

  def self.pack(archive, indir, *dirs)
    FileUtils.rm_f archive
    FileUtils.mkdir_p File.dirname(archive)
    dirs << '.' if dirs.empty?
    # gnu tar and bsd tar use different options to  derefence symlinks
    args = []
    #args << (['tar', 'gtar'].include?(tar_prog)) ? '--dereference' : '-L'
    args += ['--format', 'ustar', '-C', indir, '-Jcf', archive] + dirs
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

  def self.crew_ar_prog
    @@crew_ar_prog
  end

  def self.crew_tar_prog
    @@crew_tar_prog
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
    cp = "#{Global::TOOLS_DIR}/bin/curl#{Global::EXE_EXT}"
    @@curl_prog ||= Pathname.new(cp).realpath
  rescue
    warning "not found 'curl' program at the expected path: #{cp}"
    @@curl_prog = @@system_curl
  end

  def self.tar_prog
    @@tar_prog = File.exist?(@@crew_tar_prog) ? @@crew_tar_prog : 'tar'
  end

  def self.use_tar_copy_prog
    if not File.exist? @@crew_tar_prog
      @@tar_prog = nil
    else
      FileUtils.cp @@crew_tar_prog, @@crew_tar_copy_prog
      @@tar_prog = @@crew_tar_copy_prog
    end
  end

  def self.reset_tar_prog
    @@tar_prog = nil
    FileUtils.rm_f @@crew_tar_copy_prog
  end

  def self.xz_prog
    @@xz_prog ||= File.exist?(@@crew_xz_prog) ? @@crew_xz_prog : 'xz'
  end

  def self.use_xz_copy_prog
    if not File.exist? @@crew_xz_prog
      @@xz_prog = nil
    else
      FileUtils.cp @@crew_xz_prog, @@crew_xz_copy_prog
      @@xz_prog = @@crew_xz_copy_prog
    end
  end

  def self.reset_xz_prog
    @@xz_prog = nil
    FileUtils.rm_f @@crew_xz_copy_prog
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
      if ENV.has_key?('SSH_AUTH_SOCK')
        Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
      else
        Rugged::Credentials::SshKey.new(username: 'git',
                                        publickey: File.expand_path("~/.ssh/id_rsa.pub"),
                                        privatekey: File.expand_path("~/.ssh/id_rsa"))
      end
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
