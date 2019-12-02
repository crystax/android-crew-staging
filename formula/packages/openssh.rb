class Openssh < Package

  desc 'Command line and full screen utilities for browsing procfs'
  homepage 'https://www.openssh.com'
  url 'git@git.crystax.net:android/vendor-openssh.git|ref:4de3053e9b9caffa66ac31bcb3e4f324ef8b12ce'
  url 'https://github.com/crystax/android-vendor-openssh.git|commit:4de3053e9b9caffa66ac31bcb3e4f324ef8b12ce'

  release '7.7p1', crystax: 6

  depends_on 'openssl'

  build_copy 'LICENCE'
  build_options sysroot_in_cflags:    false,
                ldflags_in_c_wrapper: true,
                add_deps_to_cflags: true,
                add_deps_to_ldflags: true,
                copy_installed_dirs:  ['bin', 'etc', 'libexec', 'sbin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-nls",
	      "--with-pie",
	      "--with-Werror",
	      "--disable-etc-default-login",
	      "--disable-lastlog",
	      "--disable-utmp",
	      "--disable-utmpx",
	      "--disable-wtmp",
	      "--disable-wtmpx",
	      "--disable-strip",
	      "--disable-libutil",
	      "--disable-pututline",
	      "--disable-pututxline",
	      "--without-rpath",
	      "--with-default-path=/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin",
	      "--with-privsep-path=#{install_dir_for_abi(abi)}/var/empty"
            ]

    configure *args
    make
    make 'install-nokeys'
  end
end
