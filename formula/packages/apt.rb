class Apt < Package

  desc "apt is the main commandline package manager for Debian and its derivatives"
  homepage "https://github.com/Debian/apt"
  url "https://github.com/Debian/apt/archive/${version}.tar.gz"

  release version: '1.5.1', crystax_version: 1

  build_options build_outside_source_tree: true,
                use_standalone_toolchain: ['berkley-db', 'curl', 'gnu-tls', 'xz', 'lz4'],
                copy_installed_dirs: ['bin', 'etc', 'include', 'lib', 'libexec', 'var'],
                gen_android_mk: false

  build_copy 'COPYING'

  depends_on 'berkley-db'
  depends_on 'curl'
  depends_on 'gnu-tls'

  def build_for_abi(abi, toolchain,  release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    src_dir = source_directory(release)

    # on linux cmake linked against dynamic libcurl library
    # if we do not unset LD_LIBRARY_PATH it will try to use crew's libcurl
    # which may or may not have the required version
    build_env['PATH'] = Build.path
    build_env['LD_LIBRARY_PATH'] = nil if Global::OS == 'linux'

    cc = toolchain.gcc
    cxx = toolchain.gxx
    cflags = toolchain.gcc_cflags(abi)
    cflags += ' -Wl,--no-warn-mismatch' if abi == 'armeabi-v7a-hard'
    cxxflags = cflags
    ldflags = toolchain.gcc_ldflags(abi)

    config_args = [
      "WITH_DOC=OFF",
      "USE_NLS=OFF",
      "CMAKE_MAKE_PROGRAM=make",
      "CMAKE_VERBOSE_MAKEFILE=ON",
      "CMAKE_INSTALL_PREFIX=#{install_dir}",

      "PERL_EXECUTABLE=#{`which perl`.strip}",
      "DPKG_DATADIR=#{toolchain.sysroot_dir}/share/dpkg",

      "CMAKE_SYSTEM_NAME=Linux",
      "CMAKE_C_COMPILER=#{cc}",
      "CMAKE_CXX_COMPILER=#{cxx}",
      "CMAKE_C_FLAGS=\"#{cflags}\"",
      "CMAKE_CXX_FLAGS=\"#{cxxflags}\"",
      "CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=ONLY",
      "CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY",
      "CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY",
      "CMAKE_FIND_ROOT_PATH=#{toolchain.sysroot_dir}",

      "CMAKE_INCLUDE_PATH=#{toolchain.sysroot_dir}/usr/include",
      "CMAKE_LIBRARY_PATH=#{toolchain.sysroot_dir}/usr/lib",

      "COMMON_ARCH=#{Deb.arch_for_abi(abi)}"
    ]

    system 'cmake', src_dir, *config_args.map { |arg| "-D#{arg}" }

    apt_private_ver = find_version_in_cmake_list(src_dir, 'apt-private')
    apt_inst_ver    = find_version_in_cmake_list(src_dir, 'apt-inst')
    apt_pkg_ver     = apt_pkg_version(src_dir)

    fix_lib_link_txt('apt-private', apt_private_ver)
    fix_lib_link_txt('apt-inst',    apt_inst_ver)
    fix_lib_link_txt('apt-pkg',     apt_pkg_ver)

    fix_config_h if Global::OS == 'linux'

    if Build::BAD_ABIS.include? abi
      Dir['cmdline/CMakeFiles/*.dir', 'methods/CMakeFiles/*.dir'].each do |dir|
        libs =
          case dir
          when /(ftp|mirror|http)\.dir$/
            '-lffi -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lgmp -llz4 -llzma -lz'
          when /curl\.dir$/
            '-lssh2 -lssl -lcrypto -llz4 -llzma -lz'
          else
            '-llz4 -llzma -lz'
          end
        fix_exe_link_txt(dir, libs, ldflags)
      end
    end

    # todo: hack, remove when libcrystax is fixed
    fix_crystax_resolv_h toolchain.sysroot_dir

    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    clean_install_dir abi, :lib
    FileUtils.cd(install_dir) do
      if Global::OS == 'linux'
        FileUtils.mv 'lib', 'libexec'
        FileUtils.mkdir_p 'lib'
        FileUtils.mv Dir['libexec/*.so.*'], 'lib/'
      end
      FileUtils.cd('lib') do
        FileUtils.mv "libapt-inst.so.#{apt_inst_ver}",       'libapt-inst.so'
        FileUtils.mv "libapt-pkg.so.#{apt_pkg_ver}",         'libapt-pkg.so'
        FileUtils.mv "libapt-private.so.#{apt_private_ver}", 'libapt-private.so'
      end
      FileUtils.rm 'bin/apt-cdrom'
      FileUtils.rm 'libexec/apt/methods/cdrom'
    end
  end

  def fix_crystax_resolv_h(sysroot_dir)
    file = "#{sysroot_dir}/usr/include/crystax/bionic/libc/include/mangled-resolv.h"
    content = []
    fixed = false
    File.read(file).split("\n").each do |line|
      case line
      when /^\/\* todo: this is handcopied \*\/$/
        fixed = true
      when /^#pragma GCC visibility pop/
        if not fixed
          content += ['/* todo: this is handcopied */',
                      'int res_init(void);',
                      'int res_mkquery(int __opcode, const char* __domain_name, int __class, int __type, const u_char* __data, int __data_size, const u_char* __new_rr_in, u_char* __buf, int __buf_size);',
                      'int res_query(const char* __name, int __class, int __type, u_char* __answer, int __answer_size);',
                      'int res_search(const char* __name, int __class, int __type, u_char* __answer, int __answer_size);',
                      ''
                     ]
        end
      end
      content << line
    end

    File.open(file, 'w') { |f| f.puts content.join("\n") } unless fixed
  end

  def fix_config_h
    replace_lines_in_file('include/config.h') do |line|
      if line.start_with? "#define LIBEXEC_DIR "
        line.sub(/install\/lib\/apt"$/, 'install/libexec/apt"')
      else
        line
      end
    end
  end

  def fix_lib_link_txt(name, ver)
    major_ver = ver.split('.').first(2).join('.')

    ["#{name}/CMakeFiles/#{name}.dir/link.txt", "#{name}/CMakeFiles/#{name}.dir/relink.txt"].each do |file|
      if File.exist? file
        replace_lines_in_file(file) do |line|
          line
            .sub(/ -Wl,-soname,lib#{name}.so.#{major_ver}/, " -Wl,-soname,lib#{name}.so")
            .sub(/ -Wl,-version-script=".*"[ \t]*$/, "")
            .sub(/ -Wl,-rpath,\S+/, "")
        end
      end
    end
  end

  def fix_exe_link_txt(dir, libs, ldflags)
    ["#{dir}/link.txt", "#{dir}/relink.txt"].each do |file|
      if File.exist? file
        replace_lines_in_file(file) do |line|
          line.sub(/-Wl,-rpath,\S+/, "") +  ldflags + ' ' + libs
        end
      end
    end
  end

  def find_version_in_cmake_list(src_dir, dir)
    file = "#{src_dir}/#{dir}/CMakeLists.txt"
    major = nil
    minor = nil
    File.read(file).split("\n").each do |line|
      line.strip!
      case line
      when /^set\(MAJOR/
        major = line.split(' ')[1].chop
      when /^set\(MINOR/
        minor = line.split(' ')[1].chop
      else
        break if major and minor
      end
    end

    raise "not found major version in #{file}" unless major
    raise "not found minor version in #{file}" unless minor

    major + '.' + minor
  end

  def apt_pkg_version(src_dir)
    file = "#{src_dir}/apt-pkg/contrib/macros.h"
    major = nil
    minor = nil
    patch = nil

    File.read(file).split("\n").each do |line|
      line.strip!
      case line
      when /^#define APT_PKG_MAJOR/
        major = line.split(' ')[2].strip
      when /#define APT_PKG_MINOR/
        minor = line.split(' ')[2]
      when /#define APT_PKG_RELEASE/
        patch = line.split(' ')[2]
      else
        break if major and minor and patch
      end
    end

    raise "not found major version in #{file}" unless major
    raise "not found minor version in #{file}" unless minor
    raise "not found patch version in #{file}" unless patch

    [major, minor, patch].join('.')
  end
end
