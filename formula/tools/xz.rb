class Xz < BuildDependency

  desc "General-purpose data compression with high compression ratio"
  homepage "http://tukaani.org/xz/"
  url "http://tukaani.org/xz/xz-${version}.tar.xz"

  release version: '5.2.2', crystax_version: 1, sha256: { linux_x86_64:   '0bf361b508924bc91edb16c9a5cf2a2c7298ebd1316c4183814822f693ea45d4',
                                                          darwin_x86_64:  'c1e49d93603c672ae786853de896583a999f65264ea4bb8deecf288b7ad8b9bb',
                                                          windows_x86_64: 'ef600c460d4145499a7cd31f621ce87a9e79dc13524b3f9d2f3697be52e8ceab',
                                                          windows:        '3cd9a05f91df830362d6112842c783fc2f4717d85dc4bb3a9de276768b383b35'
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
