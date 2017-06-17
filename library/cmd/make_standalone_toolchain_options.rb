require_relative '../toolchain.rb'
require_relative '../command_options.rb'

class MakeStandaloneToolchainOptions

  PackageInfo = Struct.new(:name, :release)

  extend CommandOptions

  attr_reader :install_dir, :gcc, :llvm, :stl, :arch, :platform, :api_level, :with_packages

  def initialize(opts)
    gcc_version = Toolchain::DEFAULT_GCC.version
    llvm_version = Toolchain::DEFAULT_LLVM.version

    @stl = 'gnustl'
    @platform = Platform.new(Global::PLATFORM_NAME)
    @with_packages = []

    opts.each do |opt|
      case opt
      when /^--install-dir=/
        @install_dir = opt.split('=')[1]
        raise "#{@install_dir} must be empty or non existent directory: " if Dir.exists?(@install_dir) and !Dir.empty?(@install_dir)
      when /^--gcc-version=/
        gcc_version = opt.split('=')[1]
        raise "unsupported GCC version #{gcc_version}" unless Toolchain::SUPPORTED_GCC.map(&:version).include? gcc_ver
      when /^--llvm-version=/
        llvm_version = opt.split('=')[1]
        raise "unsupported LLVM version #{llvm_version}" unless Toolchain::SUPPORTED_LLVM.map(&:version).include? llvm_ver
      when /^--stl=/
        @stl = opt.split('=')[1]
        raise "unsupported STL #{@stl}" unless ['gnustl', 'libc++'].include? @stl
      when /^--arch=/
        arch_name = opt.split('=')[1]
        raise "unsupported architecure #{arch_name}" unless Arch.supported? arch_name
        @arch = Arch::LIST[arch_name.to_sym].dup
      when /^--platform=/
        platform_name = opt.split('=')[1]
        raise "platform #{platform} unsupported on #{Global::OS}" unless Platform.default_names_for_host_os.include? platform_name
        @platfrom = Platfrom.new(platfrom_name)
      when /^--api-level=/
        @api_level = opt.split('=')[1].to_int
      when /^--with-packages=/
        package_names = opt.split('=')[1].split(',')
      else
        raise "unknow option: #{opt}"
      end
    end

    raise "architecture must be specified" unless @arch

    @api_level ||= arch.min_api_level

    @gcc = Toolchain::GCC.new(gcc_version)
    @llvm = Toolchain::LLVM.new(llvm_version, gcc)

    # todo: check that specified packages are available
  end
end
