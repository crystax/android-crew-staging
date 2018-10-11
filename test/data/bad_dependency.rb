class BadDependency < Package

  desc "Bad Dependency"
  name 'bad-dependency'
  homepage "http://www.baddependency.org"

  release '1.1.0', crystax: 1

  depends_on 'foo'
end
