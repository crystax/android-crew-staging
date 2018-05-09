class BerkleyDb < Package

  name 'berkley-db'
  desc 'Berkeley DB is a family of embedded key-value database libraries providing scalable high-performance data management services to applications'
  homepage 'http://www.oracle.com/technetwork/database/database-technologies/berkeleydb/overview/'
  url 'http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz'

  release version: '6.2.32', crystax_version: 2

  build_copy 'LICENSE'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain,  release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-compat185",
              "--enable-cxx",
              "--disable-localization",
              "--enable-static",
              "--enable-shared",
              "--with-pic",
              "--with-sysroot",
              "--with-cryptography=no"
            ]

    FileUtils.cd('build_android') do
      system '../dist/configure', *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end

    clean_install_dir abi, :lib

    FileUtils.cd("#{install_dir}/lib") do
      v = release.major_point_minor
      FileUtils.rm "libdb-#{v}.a"
      FileUtils.rm "libdb_cxx-#{v}.a"
      FileUtils.mv "libdb-#{v}.so",     "libdb.so"
      FileUtils.mv "libdb_cxx-#{v}.so", "libdb_cxx.so"
    end
  end

  def sonames_translation_table(release)
    v = release.major_point_minor
    { "libdb-#{v}.so"     => 'libdb',
      "libdb_cxx-#{v}.so" => 'libdb_cxx'
    }
  end
end
