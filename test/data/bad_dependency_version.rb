class BadDependencyVersion < Package

  desc "Bad Dependency Version"
  name 'bad-dependency-version'
  homepage "http://www.baddependencyversion.org"

  release '1.1.0', crystax: 1

  depends_on 'libtwo', version: /^10/
end
