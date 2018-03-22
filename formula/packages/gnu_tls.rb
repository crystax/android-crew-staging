class GnuTls < Package

  name 'gnu-tls'
  desc "GnuTLS is a secure communications library implementing the SSL, TLS and DTLS protocols and technologies around them"
  homepage "https://www.gnutls.org"
  url "https://www.gnupg.org/ftp/gcrypt/gnutls/v${block}/gnutls-${version}.tar.xz" do |r| r.version.split('.').first(2).join('.') end

  release version: '3.5.18', crystax_version: 2

  depends_on 'gmp'
  depends_on 'libffi'
  depends_on 'nettle'
  depends_on 'libunistring'
  depends_on 'libidn2'
  depends_on 'p11-kit'

  build_copy 'LICENSE'
  build_options use_cxx: true,
                gen_android_mk: false,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    gmp_dir = target_dep_dirs['gmp']
    nettle_dir = target_dep_dirs['nettle']
    libidn2_dir = target_dep_dirs['libidn2']
    p11_kit_dir = target_dep_dirs['p11-kit']

    build_env['CFLAGS']  += target_dep_dirs.values.inject('') { |acc, dir| "#{acc} -I#{dir}/include" }
    build_env['LDFLAGS'] += target_dep_dirs.values.inject('') { |acc, dir| "#{acc} -L#{dir}/libs/#{abi}" }
    build_env['LDFLAGS'] += ' -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz' if ['mips', 'arm64-v8a', 'mips64'].include? abi

    build_env['GMP_CFLAGS']     = "-I#{gmp_dir}/include"
    build_env['GMP_LIBS']       = "-L#{gmp_dir}/libs/#{abi} -lgmp"
    build_env['NETTLE_CFLAGS']  = "-I#{nettle_dir}/include"
    build_env['NETTLE_LIBS']    = "-L#{nettle_dir}/libs/#{abi} -lnettle"
    build_env['HOGWEED_CFLAGS'] = "-I#{nettle_dir}/include"
    build_env['HOGWEED_LIBS']   = "-L#{nettle_dir}/libs/#{abi} -lhogweed"
    build_env['LIBIDN_CFLAGS']  = "-I#{libidn2_dir}/include"
    build_env['LIBIDN_LIBS']    = "-L#{libidn2_dir}/libs/#{abi} -lidn2"
    build_env['P11_KIT_CFLAGS'] = "-I#{p11_kit_dir}/include -I#{p11_kit_dir}/include/p11-kit-1"
    build_env['P11_KIT_LIBS']   = "-L#{p11_kit_dir}/libs/#{abi} -lp11-kit"

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-doc",
              "--enable-shared",
              "--enable-static",
              "--disable-nls",
              "--with-included-libtasn1",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args

    fix_makefile if ['mips', 'arm64-v8a', 'mips64'].include? abi

    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end

  # for some reason libtool for some abis does not handle dependency libs
  def fix_makefile
    replace_lines_in_file('src/Makefile') do |line|
      if not line =~ /^LIBS =[ \t]*/
        line
      else
        line.gsub('LIBS =', 'LIBS = -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz ')
      end
    end
  end
end
