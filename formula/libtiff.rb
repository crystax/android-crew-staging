require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libtiff < Library

  desc "TIFF library"
  homepage "http://www.remotesensing.org/libtiff/"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release version: '4.0.6', crystax_version: 1, sha256: '0'

  depends_on 'libjpeg'

  build_options use_cxx: true
  patch :DATA

  def build_for_abi(abi, dep_dirs)
    libjpeg_dir = dep_dirs['libjpeg']
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-jpeg-include-dir=#{libjpeg_dir}/include",
              "--with-jpeg-lib-dir=#{libjpeg_dir}/libs/#{abi}",
              "--disable-jbig",
              "--disable-lzma",
              "--enable-cxx"
            ]

    system './configure', *args
    system 'make', '-j', 1
    system 'make', 'install'
  end
end

__END__
diff --git a/config/config.sub b/config/config.sub
index 6759825..779b034 100755
--- a/config/config.sub
+++ b/config/config.sub
@@ -120,7 +120,7 @@ esac
 # Here we must recognize all the valid KERNEL-OS combinations.
 maybe_os=`echo $1 | sed 's/^\(.*\)-\([^-]*-[^-]*\)$/\2/'`
 case $maybe_os in
-  nto-qnx* | linux-gnu* | linux-dietlibc | linux-newlib* | linux-uclibc* | \
+  nto-qnx* | linux-gnu* | linux-dietlibc | linux-newlib* | linux-uclibc* | linux-android* | \
   uclinux-uclibc* | uclinux-gnu* | kfreebsd*-gnu* | knetbsd*-gnu* | netbsd*-gnu* | \
   storm-chaos* | os2-emx* | rtmk-nova*)
     os=-$maybe_os
@@ -242,6 +242,7 @@ case $basic_machine in
 	| alpha64 | alpha64ev[4-8] | alpha64ev56 | alpha64ev6[78] | alpha64pca5[67] \
 	| am33_2.0 \
 	| arc | arm | arm[bl]e | arme[lb] | armv[2345] | armv[345][lb] | avr | avr32 \
+	| aarch64 \
 	| bfin \
 	| c4x | clipper \
 	| d10v | d30v | dlx | dsp16xx \
