require_relative "#{Global::NDK_DIR}/../data/test_tool_methods.rb"

class TestTool < Tool

  include MultiVersion

  desc 'Test Tool'
  url ''

  release '1.0.0'
  release '2.0.0'
  release '3.0.0'
  release '4.0.0'

  include TestToolMethods
end
