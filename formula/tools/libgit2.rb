class Libgit2 < Utility

  desc "A portable, pure C implementation of the Git core methods provided as a re-entrant linkable library with a solid API"
  homepage 'https://libgit2.github.com/'
  url 'https://github.com/libgit2/libgit2/archive/v${version}.tar.gz'

  release version: '0.26.0', crystax_version: 2

  depends_on 'zlib'
  depends_on 'openssl'
  depends_on 'libssh2'

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir   = Global::tools_dir(platform.name)

    config_args = [
      "CREW_SHARED_LIB_EXT=#{Build.shared_lib_link_extension(platform.target_os)}",
      "CREW_ISYSROOT=#{platform.sysroot}",
      "CREW_LIB_DIR=#{tools_dir}/lib",
      "CMAKE_VERBOSE_MAKEFILE=ON",
      "CMAKE_INSTALL_PREFIX=#{install_dir}",
      "CMAKE_C_COMPILER=#{platform.cc}",
      "CMAKE_C_FLAGS=\"#{platform.cflags} -I#{tools_dir}/include\"",
      "CMAKE_FIND_ROOT_PATH=#{tools_dir}",
      "BUILD_CLAR=OFF",
      "USE_ICONV=OFF"
    ]
    if platform.target_os == 'windows'
      config_args += ["WIN32=ON",
                      "MINGW=ON",
                      "DLLTOOL=#{platform.dlltool}",
                      "CMAKE_RC_COMPILER=\"#{platform.windres}\"",
                      "CMAKE_SYSTEM_NAME=Windows"
                     ]
    end

    build_env['LD_LIBRARY_PATH'] = nil if ['linux', 'windows'].include? platform.target_os

    system 'cmake', src_dir, *config_args.map { |arg| "-D#{arg}" }
    system 'cmake', '--build', '.', '--target', 'install'

    # fix dylib install names on darwin
    if platform.target_os == 'darwin'
      git2_lib = "libgit2.#{release.version}.dylib"
      system 'install_name_tool', '-id', "@rpath/#{git2_lib}", "#{install_dir}/lib/#{git2_lib}"
      system 'install_name_tool', '-add_rpath', '@executable_path/../lib', "#{install_dir}/lib/#{git2_lib}"
    end

    # remove unneeded files
    FileUtils.rm_rf "#{install_dir}/lib/pkgconfig"
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end
end
