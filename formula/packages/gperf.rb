class Gperf < Package

  name 'gperf'
  desc "GNU gperf is a perfect hash function generator"
  homepage "https://www.gnu.org/software/gperf/"
  url "http://ftp.gnu.org/pub/gnu/gperf/gperf-${version}.tar.gz"

  release '3.1', crystax: 2

  build_copy 'COPYING'
  build_options use_cxx: true, copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    build_env['CXXFLAGS'] += ' -lgnustl_shared'

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf "#{install_dir}/share"
  end
end
