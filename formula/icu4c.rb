class Icu4c < Library

  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "http://site.icu-project.org/"
  url "https://ssl.icu-project.org/files/icu4c/${version}/icu4c-${block}-src.tgz" do |v| v.gsub('.', '_') end

  release version: '56.1', crystax_version: 1, sha256: '0'

  patch :DATA
  build_libs 'libicudata', 'libicui18n', 'libicuio', 'libicule', 'libiculx', 'libicutest', 'libicutu', 'libicuuc'
  build_options use_cxx: true,
                wrapper_filter_out: ['-m32', '-m64']

  def prebuild(src_dir)
    base_dir = build_base_dir
    build_dir = "#{build_base_dir}/native"
    FileUtils.mkdir_p build_dir
    FileUtils.cp_r "#{src_dir}/.", build_dir

    write_host_wrapper 'gcc', build_dir
    write_host_wrapper 'g++', build_dir
    build_env['PATH'] = "#{build_dir}:#{ENV['PATH']}"

    FileUtils.cd(build_dir) do
      system './source/runConfigureICU', icu_host_platform
      system 'make', '-j', num_jobs
    end

    build_dir
  end

  def build_for_abi(abi, dep_dirs)
    native_build_dir = prebuild_result

    args = [ "--prefix=#{install_dir_for_abi(abi)}",
             "--host=#{host_for_abi(abi)}",
             "--enable-shared",
             "--enable-static",
             "--with-cross-build=#{native_build_dir}"
           ]

    build_env['CFLAGS'] << ' -fPIC -DU_USING_ICU_NAMESPACE=0 -DU_CHARSET_IS_UTF8=1'
    build_env['LDFLAGS'] << ' -lgnustl_shared'

    build_env['CFLAGS'] << ' -m32'               if abi == 'x86'
    build_env['CFLAGS'] << ' -m64'               if abi == 'x86_64'
    build_env['CFLAGS'] << ' -mabi=32 -mips32'   if abi == 'mips'
    build_env['CFLAGS'] << ' -mabi=64 -mips64r6' if abi == 'mips64'

    build_env['LDFLAGS'] << " -Wl,--fix-cortex-a8" if ['armeabi-v7a', 'armeabi-v7a-hard'].include? abi

    system './source/configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

  end

  def icu_host_platform
    case Global::OS
    when 'darwin'
      'MacOSX/GCC'
    when 'linux'
      'Linux'
    else
      raise 'unsuppoted ICU host platform'
    end
  end

  def write_host_wrapper(name, dir)
    cc = "/Volumes/Source-HD/src/ndk/platform/prebuilts/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin/#{name}"
    filename = "#{dir}/#{name}"
    File.open(filename, 'w') do |f|
      f.puts '#!/bin/sh'
      f.puts ''
      f.puts "exec #{cc} -m32 -isysroot /Volumes/Source-HD/src/ndk/platform/prebuilts/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=10.6 -DMACOSX_DEPLOYMENT_TARGET=10.6  -Wl,-syslibroot,/Volumes/Source-HD/src/ndk/platform/prebuilts/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=10.6 \"$@\""
    end
    FileUtils.chmod "a+x", filename
  end
end

__END__
diff -wr -U 4 a/source/tools/toolutil/flagparser.c b/source/tools/toolutil/flagparser.c
--- a/source/tools/toolutil/flagparser.c	2015-10-08 06:54:06.000000000 +0300
+++ b/source/tools/toolutil/flagparser.c	2015-12-26 00:04:09.000000000 +0300
@@ -96,9 +96,9 @@
     uprv_free(buffer);

     T_FileStream_close(f);

-    if (U_FAILURE(*status)) {
+    if (U_FAILURE(*status) && (*status != U_BUFFER_OVERFLOW_ERROR)) {
         return -1;
     }

     if (U_SUCCESS(*status) && result == 0) {
