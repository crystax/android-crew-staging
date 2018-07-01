class InfoZip < Package

  name 'info-zip'
  desc 'Zip - a compressor/archiver for creating and modifying zipfiles'
  homepage 'http://www.info-zip.org/Zip.html'
  url 'https://sourceforge.net/projects/infozip/files/Zip%203.x%20%28latest%29/${version}/zip${block}.tar.gz'  do |r| r.version.split('.').first(2).join end

  release '3.0', crystax: 2

  build_copy 'LICENSE'
  build_options cflags_in_c_wrapper:  true,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false


  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    build_env['PATH'] = "#{Dir.pwd}:#{ENV['PATH']}"

    system "make -j #{num_jobs} -f unix/Makefile generic"

    install_bin_dir = "#{install_dir_for_abi(abi)}/bin"
    FileUtils.mkdir_p install_bin_dir
    FileUtils.cp 'zip', install_bin_dir
  end
end
