class Erlang < Package

  desc "Programming language for highly scalable real-time systems"
  homepage "https://www.erlang.org/"
  url "https://github.com/erlang/otp/archive/OTP-${version}.tar.gz"

  release version: '19.2.3', crystax_version: 1, sha256: '0'

  #depends_on 'ncurses'
  depends_on 'openssl'

  build_options sysroot_in_cflags:    false,
                ldflags_in_c_wrapper: true,
                debug_compiler_args:  true,
                copy_installed_dirs:  [],
                gen_android_mk:       false

  build_copy 'LICENSE.txt'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs)
    install_dir = install_dir_for_abi(abi)
    #ncurses_dir = target_dep_dirs['ncurses']
    openssl_dir = target_dep_dirs['openssl']

    build_env['CFLAGS'] << " -I#{openssl_dir}/include"
    build_env['CFLAGS'] << ' -mthumb' if abi =~ /^armeabi/
    build_env['LDFLAGS'] << " -L#{openssl_dir}/libs/#{abi}"

    build_env['ERL_TOP']           = Dir.pwd

    system './otp_build autoconf'
    system './otp_build', 'configure', "--xcomp-conf=#{gen_xcomp_file(abi, openssl_dir)}"
    system 'make', 'noboot', '-j', num_jobs, 'V=1'
    system './otp_build', 'release', '-a', "#{install_dir}/#{abi}"

    FileUtils.cp_r "#{install_dir}/#{abi}", package_dir
  end

  def gen_xcomp_file(abi, openssl_dir)
    file = "xcomp-crystax-#{abi}.conf"
    File.open(file, 'w') do |f|
      f.puts '## -*-shell-script-*-'
      f.puts 'erl_xcomp_build=guess'
      f.puts "erl_xcomp_host=#{host_for_abi(abi)}"
      f.puts "erl_xcomp_configure_flags=\"--disable-hipe --without-termcap --without-javac --disable-dynamic-ssl-lib --with-ssl=#{openssl_dir}\""
      f.puts "erl_xcomp_sysroot=#{Build.sysroot(abi)}"
    end
    file
  end
end
