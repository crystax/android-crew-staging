require_relative '../../toolchain.rb'
require_relative '../../release.rb'
require_relative '../command.rb'


module Crew

  class MakeStandaloneToolchain < Command

    class Options < Command::Options

      PackageInfo = Struct.new(:name, :release, :formula) do
        def initialize(name, release = nil, formula = nil)
          super name, release, formula
        end

        def to_s
          "#{name}:#{release}"
        end
      end

      attr_reader :install_dir, :gcc, :llvm, :stl, :arch, :platform, :api_level, :with_packages

      def initialize(opts)
        @clean_install_dir = false
        @stl = 'gnustl'
        @platform = Platform.new(Global::PLATFORM_NAME)
        @with_packages = []

        package_names = []
        gcc_version = Toolchain::DEFAULT_GCC.version
        llvm_version = Toolchain::DEFAULT_LLVM.version

        opts.each do |opt|
          case opt
          when /^--clean-install-dir$/
            @clean_install_dir = true
          when /^--install-dir=/
            @install_dir = opt.split('=')[1]
          when /^--gcc-version=/
            gcc_version = opt.split('=')[1]
            raise "unsupported GCC version #{gcc_version}" unless Toolchain::SUPPORTED_GCC.map(&:version).include? gcc_version
          when /^--llvm-version=/
            llvm_version = opt.split('=')[1]
            raise "unsupported LLVM version #{llvm_version}" unless Toolchain::SUPPORTED_LLVM.map(&:version).include? llvm_version
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
            @platform = Platform.new(platform_name)
          when /^--api-level=/
            @api_level = opt.split('=')[1].to_i
          when /^--with-packages=/
            package_names = opt.split('=')[1].split(',')
          else
            raise "unknow option: #{opt}"
          end
        end

        raise "--install-dir must be specified" unless @install_dir
        FileUtils.rm_rf @install_dir if @clean_install_dir
        raise "#{@install_dir} must be empty or non existent directory: " if Dir.exists?(@install_dir) and !Dir.empty?(@install_dir)

        raise "architecture must be specified" unless @arch

        @api_level ||= arch.min_api_level

        @gcc = Toolchain::GCC.new(gcc_version)
        @llvm = Toolchain::LLVM.new(llvm_version, gcc)

        package_names.each do |package|
          name, release = package.split(':')
          with_packages << PackageInfo.new(name, Release.new(release))
        end
      end
    end
  end
end
