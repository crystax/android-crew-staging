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

    build_env['PATH'] = Build.path

    cc = toolchain.gcc
    cxx = toolchain.gxx
    cflags = toolchain.gcc_cflags(abi)
    cflags += ' -Wl,--no-warn-mismatch' if abi == 'armeabi-v7a-hard'
    cxxflags = cflags

    config_args = [
      "WITH_DOC=OFF",
      "USE_NLS=OFF",
      "CMAKE_VERBOSE_MAKEFILE=ON",
      "CMAKE_INSTALL_PREFIX=#{install_dir}",

      "PERL_EXECUTABLE=#{`which perl`.strip}",
      "DPKG_DATADIR=#{install_dir}/share/dpkg",

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
      "CMAKE_LIBRARY_PATH=#{toolchain.sysroot_dir}/usr/lib"
    ]
    system 'cmake', src_dir, *config_args.map { |arg| "-D#{arg}" }

    apt_inst_ver    = find_version_in_cmake_list(src_dir, 'apt-inst')
    apt_private_ver = find_version_in_cmake_list(src_dir, 'apt-private')
    apt_pkg_ver     = apt_pkg_version(src_dir)

    fix_link_txt('apt-private', apt_private_ver)
    fix_link_txt('apt-inst',    apt_inst_ver)
    fix_link_txt('apt-pkg',     apt_pkg_ver)

    if Build::BAD_ABIS.include? abi
      add_libs('apt-dump-solver', '-llz4 -llzma -lz')
    end

    # todo: hack, remove when libcrystax is fixed
    fix_crystax_resolv_h toolchain.sysroot_dir

    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    clean_install_dir abi, :lib
    FileUtils.cd(install_dir) do
      FileUtils.cd('lib') do
        FileUtils.mv "libapt-inst.so.#{apt_inst_ver}",       'libapt-inst.so'
        FileUtils.mv "libapt-pkg.so.#{apt_pkg_ver}",         'libapt-pkg.so'
        FileUtils.mv "libapt-private.so.#{apt_private_ver}", 'libapt-private.so'
      end
      FileUtils.rm 'bin/apt-cdrom'
      FileUtils.rm 'libexec/apt/methods/cdrom'
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

  def fix_link_txt(name, ver)
    major_ver = ver.split('.').first(2).join('.')

    ["#{name}/CMakeFiles/#{name}.dir/link.txt", "#{name}/CMakeFiles/#{name}.dir/relink.txt"].each do |file|
      replace_lines_in_file(file) do |line|
        line
          .sub(/ -Wl,-soname,lib#{name}.so.#{major_ver}/, " -Wl,-soname,lib#{name}.so")
          .sub(/ -Wl,-version-script=".*"[ \t]*$/,        "")
          .sub(/-Wl,-rpath,.* /,                          "")
      end
    end
  end

  def fix_crystax_resolv_h(sysroot_dir)
    file = "#{sysroot_dir}/usr/include/resolv.h"
    content = []
    fixed = false
    File.read(file).split("\n").each do |line|
      case line
      when /^\/\* todo: this is handcopied \*\/$/
        fixed = true
      when /^#endif \/\* __CRYSTAX_INCLUDE/
        if not fixed
          content += ['/* todo: this is handcopied */',
                      'int res_init(void);',
                      'int res_mkquery(int __opcode, const char* __domain_name, int __class, int __type, const u_char* __data, int __data_size, const u_char* __new_rr_in, u_char* __buf, int __buf_size);',
                      'int res_query(const char* __name, int __class, int __type, u_char* __answer, int __answer_size);',
                      'int res_search(const char* __name, int __class, int __type, u_char* __answer, int __answer_size);'
                     ]
        end
      end
      content << line
    end

    File.open(file, 'w') { |f| f.puts content.join("\n") } unless fixed
  end

  def add_libs(name, libs)
    dir = "cmdline/CMakeFiles/#{name}.dir"
    ["#{dir}/link.txt", "#{dir}/relink.txt"].each do |file|
      s = File.read(file).strip
      s += ' ' + libs
      File.open(file, 'w') { |f| f.puts s }
    end
  end
end
