class Boost < Library

  desc "Boost libraries built without ICU4C"
  homepage "http://www.boost.org"
  url "https://downloads.sourceforge.net/project/boost/boost/${version}/boost_${block}.tar.bz2" do |v| v.gsub('.', '_') end

  release version: '1.60.0', crystax_version: 1, sha256: '0'

  build_options pack_libs: :copy_lib_dir

  def build_for_abi(abi, release, _)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    arch = Build.arch_for_abi(abi)
    bjam_arch, bjam_abi = bjam_data(arch)

    build_dir = "#{build_dir_for_abi(abi)}/build"
    prefix_dir = "#{build_dir_for_abi(abi)}/install"

    args = [ "-d+2",
             "-q",
             "-j#{num_jobs}",
             "variant=release",
             "link=static,shared",
             "runtime-link=shared",
             "threading=multi",
             "target-os=android",
             "binary-format=elf",
             "address-model=#{arch.num_bits}",
             "architecture=#{bjam_arch}",
             "abi=#{bjam_abi}",
             "--user-config=user-config.jam",
             "--layout=system",
             "--prefix=#{prefix_dir}",
             "--build-dir=#{build_dir}",
             without_libs(arch).map { |lib| "--without-#{lib}" },
             "install"
           ].flatten

    #stls = Build.cxx_std_libs.map { |l| Build.toolchain_for_cxx_std_lib(l) }

    [Toolchain.new('gcc',   '4.9')].each do |tc|
      set_build_env(tc, abi)
      system './b2', *args
      # todo: copy libs to
    end

    # todo: copy headers
    # install_dir_for_abi(abi)
  end

  def bjam_data(arch)
    case arch.name
    when /^arm/               # arm|arm64
      bjam_arch = 'arm'
      bjam_abi = 'aapcs'
    when /^x86/               # x86|x86_64
      bjam_arch = 'x86'
      bjam_abi  = 'sysv'
    when 'mips'
      bjam_arch = 'mips1'
      bjam_abi  = 'o32'
    when 'mips64'
      bjam_arch = 'mips1'
      bjam_abi  = 'o64'
    else
      raise UnsupportedArch.new(arch)
    end

    [bjam_arch, bjam_abi, bjam_addr_model]
  end

  def without_libs(release, arch)
    exclude = []
    major, minor, _ = release.version.split('.')

    # Boost.Context in 1.60.0 and earlier don't support mips64
    if major.to_i == 1 and minor.to_i <= 60
      exclude << 'context'
    end

    # Boost.Coroutine depends on Boost.Context
    if exclude.include? 'context'
      exclude << 'coroutine'
      # Starting from 1.59.0, there is Boost.Coroutine2 library, which depends on Boost.Context too
      if major.to_i == 1 and minor.to_i >= 59
        exclude << 'coroutine2'
      end
    end

    exclude
  end
end
