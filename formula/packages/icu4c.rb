class Icu4c < Package

  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "http://site.icu-project.org/"
  url "https://ssl.icu-project.org/files/icu4c/${version}/icu4c-${block}-src.tgz" do |r| r.version.gsub('.', '_') end

  release version: '57.1', crystax_version: 1, sha256: 'ce669530781ee7c5a16db79a7ced13a50ef950d47f1784bf856c90bc0ef6792b'

  build_libs 'libicudata', 'libicui18n', 'libicuio', 'libicule', 'libiculx', 'libicutest', 'libicutu', 'libicuuc'
  build_copy 'license.html'
  build_options use_cxx: true

  def pre_build(src_dir, _release)
    base_dir = build_base_dir
    build_dir = "#{build_base_dir}/native"
    FileUtils.mkdir_p build_dir
    FileUtils.cp_r "#{src_dir}/.", build_dir

    Build.gen_host_compiler_wrapper "#{build_dir}/gcc", 'gcc', '-m32'
    Build.gen_host_compiler_wrapper "#{build_dir}/g++", 'g++', '-m32'
    build_env['PATH'] = "#{build_dir}:#{ENV['PATH']}"

    FileUtils.cd(build_dir) do
      system './source/runConfigureICU', icu_host_platform
      system 'make', '-j', num_jobs
    end

    build_dir
  end

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs)
    native_build_dir = pre_build_result
    install_dir = install_dir_for_abi(abi)
    args = [ "--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--enable-shared",
             "--enable-static",
             "--with-cross-build=#{native_build_dir}"
           ]

    build_env['CFLAGS']  << ' -fPIC -DU_USING_ICU_NAMESPACE=0 -DU_CHARSET_IS_UTF8=1'
    build_env['LDFLAGS'] << ' -lgnustl_shared'

    build_env['CFLAGS'] << ' -mabi=32 -mips32'   if abi == 'mips'
    build_env['CFLAGS'] << ' -mabi=64 -mips64r6' if abi == 'mips64'

    system './source/configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # clean lib dir before packaging
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf ['pkgconfig', 'icu']
      build_libs.each do |f|
        FileUtils.rm ["#{f}.so", "#{f}.so.#{release.version.split('.')[0]}"]
        FileUtils.mv "#{f}.so.#{release.version}", "#{f}.so"
      end
    end
  end

  def icu_host_platform
    case Global::OS
    when 'darwin'
      'MacOSX/GCC'
    when 'linux'
      'Linux/gcc'
    else
      raise 'unsuppoted ICU host platform'
    end
  end
end
