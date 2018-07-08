require_relative "#{Global::NDK_DIR}/../data/test_base_package_methods.rb"

class TestBasePackage < BasePackage

  include MultiVersion

  desc "Test Base Package"

  release '1', crystax: 1
  release '2', crystax: 1
  release '3', crystax: 1
  release '4', crystax: 1

  include TestBasePackageMethods
end
