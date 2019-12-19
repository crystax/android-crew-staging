class Libtalloc < Package

  desc "Talloc is a hierarchical, reference counted memory pool system with destructors. It is the core memory allocator used in Samba."
  homepage "https://talloc.samba.org/"
  url "https://www.samba.org/ftp/talloc/talloc-${version}.tar.gz"

  release '2.1.14'

  def build_for_abi(abi, _toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)
    src_dir = File.join(build_base_dir, abi, 'src')
    FileUtils.rm_rf src_dir
    FileUtils.cp_r "#{source_directory(release)}/.", src_dir

    Dir.chdir(src_dir) do
      File.open('cross-answers.txt', 'w') do |f|
        f.write <<~EOF
        Checking uname sysname type: "Linux"
        Checking uname machine type: "dontcare"
        Checking uname release type: "dontcare"
        Checking uname version type: "dontcare"
        Checking simple C program: OK
        building library support: OK
        Checking for large file support: OK
        Checking for -D_FILE_OFFSET_BITS=64: OK
        Checking for WORDS_BIGENDIAN: OK
        Checking for C99 vsnprintf: OK
        Checking for HAVE_SECURE_MKSTEMP: OK
        rpath library support: OK
        -Wl,--version-script support: FAIL
        Checking correct behavior of strtoll: OK
        Checking correct behavior of strptime: OK
        Checking for HAVE_IFACE_GETIFADDRS: OK
        Checking for HAVE_IFACE_IFCONF: OK
        Checking for HAVE_IFACE_IFREQ: OK
        Checking getconf LFS_CFLAGS: OK
        Checking for large file support without additional flags: OK
        Checking for working strptime: OK
        Checking for HAVE_SHARED_MMAP: OK
        Checking for HAVE_MREMAP: OK
        Checking for HAVE_INCOHERENT_MMAP: OK
        Checking getconf large file support flags work: OK
        EOF
      end

      configure "--prefix=#{install_dir}",
        '--disable-rpath',
        '--disable-python',
        '--disable-symbol-versions',
        '--cross-compile',
        '--cross-answers=cross-answers.txt'

      make '-j', num_jobs
      make 'install'

      clean_install_dir abi
      FileUtils.cd("#{install_dir}/lib") do
        FileUtils.rm_rf "pkgconfig"
        FileUtils.mv "libtalloc.so.#{release.version}", "libtalloc.so"
      end
    end

  end

  def sonames_translation_table(release)
    v = release.version.split('.')[0]
    {
      "libtalloc.so.#{v}"  => 'libtalloc',
    }
  end
end
