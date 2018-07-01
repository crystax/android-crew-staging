class Gzip < Package

  desc 'gzip (GNU zip) is a compression utility designed to be a replacement for compress'
  homepage 'https://www.gnu.org/software/gzip/'
  url 'https://ftp.gnu.org/gnu/gzip/gzip-${version}.tar.gz'

  release '1.2.4', crystax: 2

  build_copy 'COPYING'
  build_options ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    FileUtils.mkdir_p install_dir

    args =  ["--prefix=#{install_dir}", "--host=#{host_for_abi(abi)}"]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
