class Openssl < Package

  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url 'https://openssl.org/source/openssl-${version}.tar.gz'

  release version: '1.0.2n', crystax_version: 2
  release version: '1.1.0g', crystax_version: 1

  build_options copy_installed_dirs: ['bin', 'include', 'lib']
  build_copy 'LICENSE'
  build_libs 'libcrypto', 'libssl'

  def build_for_abi(abi, toolchain, release, _host_dep_dirs, _target_dep_dirs, options)
    install_dir = install_dir_for_abi(abi)
    build_env['CFLAGS'] << ' -DOPENSSL_NO_DEPRECATED'

    args = ["--prefix=#{install_dir}",
            "shared",
            "zlib-dynamic",
            target(abi),
            build_env['CFLAGS'],
            build_env['LDFLAGS'],
           ]

    # 1.1.* uses engine/name for engine sonames
    # todo: check if we can safely remove 'engine/' prefixes from engine's sonames
    self.build_options[:check_sonames] = false if release.version =~ /^1\.1/

    # parallel build seems to be broken on darwin
    # lets try parallell build with 1.1.*
    self.num_jobs = 1 if release.version =~ /^1\.0/ and Global::OS == 'darwin' and options.num_jobs_default?

    system './Configure',  *args
    # 1.1* have no gost engine
    fix_ccgost_makefile build_dir_for_abi(abi), toolchain.ldflags(abi) if release.version =~ /^1\.0/

    system 'make', 'depend'
    system 'make', '-j', num_jobs
    system "make install"

    # prepare installed files for packaging
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.cd(File.join(install_dir, 'lib')) do
      major, minor, _ = release.version.split('.')
      build_libs.each do |f|
        FileUtils.rm "#{f}.so"
        # 1.0.* uses 1.0.0 suffix for lib names
        if release.version =~ /^1\.0/
          FileUtils.mv "#{f}.so.#{major}.#{minor}.0", "#{f}.so"
        else
          FileUtils.mv "#{f}.so.#{major}.#{minor}", "#{f}.so"
        end
      end
    end

    # copy engines
    # libs_dir = "#{package_dir}/libs/#{abi}"
    # FileUtils.mkdir_p libs_dir
    # FileUtils.cp_r File.join(install_dir, 'lib', 'engines'), libs_dir
  end

  def target(abi)
    case abi
    when 'x86'       then 'linux-elf'
    when 'x86_64'    then 'linux-x86_64'
    when /^armeabi/  then 'linux-armv4'
    when 'arm64-v8a' then 'linux-aarch64'
    when 'mips'      then 'linux-generic32'   # Looks like asm code in OpenSSL doesn't support MIPS32r6
    when 'mips64'    then 'linux-generic64'   # Looks like asm code in OpenSSL doesn't support MIPS64r6
    else
      raise "Unsupported abi #{abi}"
    end
  end

  def fix_ccgost_makefile(build_dir, ldflgs)
    makefile = File.join(build_dir, 'engines', 'ccgost', 'Makefile')
    lines = []
    replaced = false
    File.foreach(makefile) do |l|
      if not l.include?('LIBDEPS=\'-L$(TOP) -lcrypto')
        lines << l
      else
        lines << l.gsub('LIBDEPS=\'', "LIBDEPS=\'#{ldflgs} ")
        replaced = true
      end
    end

    raise "not found required line in #{makefile}" unless replaced

    File.open(makefile, 'w') { |f| f.puts lines }
  end

  def sonames_translation_table(release)
    r = release.version.split('.')
    v = "#{r[0]}.#{r[1]}"
    if release.version =~ /^1\.0/
      { "libcrypto.so.#{v}.0" => 'libcrypto',
        "libssl.so.#{v}.0"    => 'libssl'
      }
    else
      { "libcrypto.so.#{v}" => 'libcrypto',
        "libssl.so.#{v}"    => 'libssl'
      }
    end
  end
end
