class Binutils < Utility

  desc 'The GNU Binutils are a collection of binary tools'
  homepage 'https://www.gnu.org/software/binutils/'
  url 'https://ftpmirror.gnu.org/binutils/binutils-${version}.tar.xz'

  release '2.31'

  depends_on 'zlib'
  postpone_install true

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    FileUtils.cp_r Dir["#{src_dir}/*"], '.'
    tools_dir = Global::tools_dir(platform.name)

    build_env['CFLAGS']  += " -I#{tools_dir}/include"
    build_env['LDFLAGS']  = "-L#{tools_dir}/lib"

    puts '  building bfd'
    FileUtils.cd('bfd') do
      args = platform.configure_args +
             ["--disable-shared",
              "--enable-static",
              "--disable-nls"
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
    ar = platform.target_os == 'windows' ? 'ar.exe' : 'ar'
    install_dir = install_dir_for_platform(platform.name, release)
    FileUtils.cd('binutils') do
      args = platform.configure_args +
             ["--prefix=#{install_dir}",
              "--disable-host-shared"
             ]

      build_env['CFLAGS']  += ' -I../bfd/include'
      system './configure', *args
      system 'make', ar, '-j', num_jobs
    end

    install_bin_dir = "#{install_dir}/bin"
    FileUtils.mkdir_p install_bin_dir
    FileUtils.cp "binutils/#{ar}", install_bin_dir
  end
end
