class InfoUnzip < Package

  name 'info-unzip'
  desc 'UnZip is an extraction utility for archives compressed in .zip format'
  homepage 'http://www.info-zip.org/UnZip.html'
  url 'https://sourceforge.net/projects/infozip/files/UnZip%206.x%20%28latest%29/UnZip%20${version}/unzip${block}.tar.gz' do |r| r.version.split('.').first(2).join end

  release '6.0', crystax: 5

  build_copy 'LICENSE'
  build_options build_outside_source_tree: false,
                cflags_in_c_wrapper:  true,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false


  def build_for_abi(abi, _toolchain,  _release, _options)
    build_env['PATH'] = "#{Dir.pwd}:#{ENV['PATH']}"

    make '-f', 'unix/Makefile', 'generic'

    install_bin_dir = "#{install_dir_for_abi(abi)}/bin"
    FileUtils.mkdir_p install_bin_dir
    FileUtils.cp 'unzip', install_bin_dir
  end
end
