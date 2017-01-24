class Python < Utility

  desc "Interpreted, interactive, object-oriented programming language"
  homepage "https://www.python.org"

  release version: '2.7.5', crystax_version: 1, sha256: { linux_x86_64:   '363dd6932d40b06c1dec831516f760d3c396141c9fd7c39d7d22a63e8870bf30',
                                                          darwin_x86_64:  'e87f42a00f90bef99b85d885bca65a002fdee71493218c93775f957172a30d4f',
                                                          windows_x86_64: '32347aa9053e658c0451debb3c9dcbf858251b9cdd214ed1b681d0ed2604ff90',
                                                          windows:        '1656a4943c8271792539afd61f0926e398683db9bd679cb15be80ae840a9b94f'
                                                        }

  executables 'python'

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in toolchain/python repository
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'python', "Python-#{release.version}")
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--build=#{platform.toolchain_build}",
            "--host=#{platform.toolchain_host}",
            "--disable-ipv6"
           ]

    build_env['DARWIN_SYSROOT'] = platform.sysroot if platform.target_os == 'darwin'
    build_env['LDSHARED'] = "#{platform.cc} -shared "
    build_env['LDFLAGS'] = platform.cflags
    case platform.target_os
    when 'darwin'
      build_env['LDSHARED'] = "#{platform.cc} -bundle -undefined dynamic_lookup "
    when 'linux'
      build_env['CFLAGS'] += " -fPIC"
    when 'windows'
      File.open('config.site', 'w') do |f|
         f.puts "ac_cv_file__dev_ptmx=no"
         f.puts "ac_cv_file__dev_ptc=no"
      end
      build_env['CONFIG_SITE'] = 'config.site'
      build_env['CFLAGS']   += " -D__USE_MINGW_ANSI_STDIO=1"
      build_env['CXXFLAGS'] += " -D__USE_MINGW_ANSI_STDIO=1"
    end

    # By default, the Python build will force the following compiler flags
    # after our own CFLAGS:
    #   -g -fwrap -O3 -Wall -Wstrict-prototypes
    #
    # The '-g' is unfortunate because it makes the generated binaries
    # much larger than necessary, and stripping them after the fact is
    # a bit delicate when cross-compiling. To avoid this, define a
    # custom OPT variable here (see Python-2.7.5/configure.ac) when
    # generating non stripped builds.
    build_env['OPT'] = '-fwrapv -O3 -Wall -Wstrict-prototypes'

    FileUtils.cd(src_dir) do
      FileUtils.touch ['Include/graminit.h', 'Include/Python-ast.h',
                       'Python/graminit.c', 'Python/Python-ast.c',
                       'Parser/Python.asdl', 'Parser/asdl.py', 'Parser/asdl_c.py'
                      ]
      File.open('Parser/pgen.stamp', 'w') {}
    end

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    #system 'make', 'test' if options.check? platform
    system 'make', 'install'

    FileUtils.cd(install_dir) do
      FileUtils.rm_rf ['share', 'lib/pkgconfig']
      FileUtils.cd('bin') do
        FileUtils.mv 'python2.7-config',    'python2.7-config.py'
        File.open('python2.7-config', 'w') do |f|
          f.puts '#!/bin/sh'
          f.puts
          f.puts 'exec `dirname $0`/python `dirname $0`/python2.7-config.py "$@"'
        end
        FileUtils.chmod 'a+x', 'python2.7-config'
        if platform.target_os == 'windows'
          File.open('python2.7-config.cmd', 'w') do |f|
            f.puts '@echo off'
            f.puts 'set BINDIR=%~dp0'
            f.puts '"%BINDIR%\\python" "%BINDIR%\\python2.7-config.py" %*'
          end
        end
      end
    end
  end
end
