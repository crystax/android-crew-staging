class TestTool < Tool

  desc 'Test Tool'
  homepage 'https://www.test_tool.org/'
  url ''

  release version: '1.0.0', crystax_version: 1

  def install_archive(_release, _archive, _platform_name)
    # empty method
    # we need it to prevent error with non-existing list file
  end
end
