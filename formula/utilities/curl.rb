class Curl < Utility

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'
  role :core

  release version: '7.42.0', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                           linux_x86:      '0',
                                                           darwin_x86_64:  '0',
                                                           darwin_x86:     '0',
                                                           windows_x86_64: '0',
                                                           windows:        '0'
                                                         }

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'

  def build_for_platform(platform, release, options, dep_dirs)
  #   paths[:zlib]    = Builder.build_zlib    options, paths
  #   paths[:openssl] = Builder.build_openssl options, paths
  #   paths[:libssh2] = Builder.build_libssh2 options, paths

  #   Logger.log_msg "= building #{archive}; args: #{ARGV}"
  #   check_version paths[:src], release.version
  #   Builder.copy_sources paths[:src], paths[:build_base]
  #   FileUtils.mkdir_p(paths[:install])
  #   prefix = Pathname.new(paths[:install]).realpath
  #   FileUtils.cd(paths[:build]) do
  #     Commander.run "./buildconf"
  #     env = { 'CC' => Builder.cc(options),
  #             'CFLAGS' => "#{Builder.cflags(options)} -DCURL_STATICLIB",
  #             'LANG' => 'C'
  #           }
  #     env['LDFLAGS'] = ' -ldl' if options.target_os == 'linux'
  #     args = ["--prefix=#{prefix}",
  #             "--host=#{Builder.configure_host(options)}",
  #             "--disable-shared",
  #             "--disable-ldap",
  #             "--with-ssl=#{paths[:openssl]}",
  #             "--with-zlib=#{paths[:zlib]}",
  #             "--with-libssh2=#{paths[:libssh2]}"
  #            ]
  #     Commander.run env, "./configure #{args.join(' ')}"
  #     Commander.run env, "make -j #{options.num_jobs}"
  #     Commander.run env, "make test" unless options.no_check?
  #     Commander.run env, "make install"
  #     # remove unneeded files before packaging
  #     FileUtils.cd(prefix) { FileUtils.rm_rf(['include', 'lib', 'share']) }
  #   end

  #   platform_sym = options.target_platform_as_sym
  #   release.shasum = { platform_sym => Cache.add(archive, paths[:build_base]) }
  #   Common.update_release_shasum formula.path, release, platform_sym if options.update_sha256_sums?
  # end

  # if options.same_platform?
  #   Cache.unpack(archive, Common::NDK_DIR)
  #   Common.write_active_file(Common::NDK_DIR, options.host_platform, PKG_NAME, release)
  # end
  end
end
