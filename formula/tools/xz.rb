class Xz < BuildDependency

  desc "General-purpose data compression with high compression ratio"
  homepage "http://tukaani.org/xz/"
  url "http://tukaani.org/xz/xz-${version}.tar.xz"

  release version: '5.2.2', crystax_version: 1, sha256: { linux_x86_64:   '3ca8d84b5ae91aa073e335e15bbb14cfa453e2e098abdf595e19738a3e91b042',
                                                          darwin_x86_64:  'c1e49d93603c672ae786853de896583a999f65264ea4bb8deecf288b7ad8b9bb',
                                                          windows_x86_64: 'f8041496bfd4c299c2962a0adcca64614f3a2b21fe1cbae926f9d184112ae3ac',
                                                          windows:        'e11adeeae2849183f876fabb71282ce4f16ab3276283efdd213f8d060bd74866'
                                                        }

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-nls",
            "--disable-xzdec",
            "--disable-lzmadec",
            "--disable-lzmainfo",
            "--disable-lzma-links",
            "--disable-scripts",
            "--disable-doc",
            "--disable-shared",
            "--with-sysroot"
           ]
    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin/unxz', 'bin/xzcat', 'lib/liblzma.la', 'lib/pkgconfig', 'share'] }
  end
end
