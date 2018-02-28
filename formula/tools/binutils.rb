class Binutils < Utility

  desc 'The GNU Binutils are a collection of binary tools'
  homepage 'https://www.gnu.org/software/binutils/'
  url 'https://mirror.freedif.org/GNU/binutils/binutils-${version}.tar.xz'

  release version: '2.30', crystax_version: 1

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    FileUtils.cp_r Dir["#{src_dir}/*"], '.'

    puts '  building bfd'
    FileUtils.cd('bfd') do
      args = platform.configure_args +
             ["--disable-shared",
              "--enable-static",
              "--disable-nls",
              "--with-system-zlib"
             ]
      system './configure', *args
      system 'make', '-j', num_jobs
    end

    puts '  build libiberty'
    FileUtils.cd('libiberty') do
      args = platform.configure_args
      system './configure', *args
      system 'make', '-j', num_jobs
    end

    puts '  building ar'
    install_dir = install_dir_for_platform(platform.name, release)
    FileUtils.cd('binutils') do
      args = platform.configure_args +
             ["--prefix=#{install_dir}",
              "--disable-host-shared"
             ]

      build_env['CFLAGS']  += ' -I../bfd/include'
      system './configure', *args
      system 'make', 'ar', '-j', num_jobs
    end

    install_bin_dir = "#{install_dir}/bin"
    FileUtils.mkdir_p install_bin_dir
    FileUtils.cp 'binutils/ar', install_bin_dir
  end
end
