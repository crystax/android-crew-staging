class Gzip < Package

  desc 'gzip (GNU zip) is a compression utility designed to be a replacement for compress'
  homepage 'https://www.gnu.org/software/gzip/'
  url 'https://ftp.gnu.org/gnu/gzip/gzip-${version}.tar.gz'

  release '1.10', crystax: 3

  build_copy 'COPYING'
  build_options ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _options)
    args = [ "--disable-silent-rules", "--disable-rpath" ]
    configure *args
    make
    make 'install'
  end
end
