class Webrtc < Package

  desc "WebRTC library"
  homepage "https://webrtc.org/"
  url 'https://gitlab.com/cawka/precompiled-android-webrtc.git|git_commit:656a7a2da3cdefbce23143bc644aba7129a17c02'

  release version: '59', crystax_version: 1

  build_options setup_env: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    cwd = Dir.pwd
    install_dir = install_dir_for_abi(abi)
    FileUtils.mkdir_p ["#{install_dir}/lib", "#{install_dir}/include"]

    FileUtils.cp Dir["#{cwd}/#{abi}/*.so"], "#{install_dir}/lib/"
    FileUtils.cp Dir["#{cwd}/#{abi}/*.a"], "#{install_dir}/lib/"
    FileUtils.cp_r "#{cwd}/webrtc", "#{install_dir}/include/"
  end
end
