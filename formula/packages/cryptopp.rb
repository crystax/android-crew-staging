class Cryptopp < Package

  desc "CryptoPP library"
  homepage "https://sqlite.org/"
  url 'git://github.com/named-data-mobile/cryptopp.git|git_commit:c7b2e7117a8c41f8e73a6b0ae61c4820de159635'

  release version: '5.6.3-1', crystax_version: 1

  build_options setup_env: false
  build_libs 'libcryptopp'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    cwd = Dir.pwd

    system "#{Global::NDK_DIR}/ndk-build", "NDK_PROJECT_PATH=#{cwd}/extras", "APP_ABI=#{abi}", "V=1"

    install_dir = install_dir_for_abi(abi)
    FileUtils.mkdir_p ["#{install_dir}/lib", "#{install_dir}/include"]
    FileUtils.cp "#{cwd}/extras/obj/local/#{abi}/libcryptopp_shared.so", "#{install_dir}/lib/"
    FileUtils.cp "#{cwd}/extras/obj/local/#{abi}/libcryptopp_static.a", "#{install_dir}/lib/"
    FileUtils.cp Dir["#{cwd}/*.h"], "#{install_dir}/include/"
  end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
    nil
  end

  def gen_android_mk(pkg_dir, release)
    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := libcryptopp_static'
      f.puts 'LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libcryptopp_static.a'
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
      f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := libcryptopp_shared'
      f.puts 'LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libcryptopp_shared.so'
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'
      f.puts ''
    end
  end

end
