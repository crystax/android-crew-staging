class Libtwo < Package

  desc "Library Two"
  homepage "http://www.libtwo.org"

  release '1.1.0', crystax: 2
  release '2.2.0', crystax: 1

  depends_on 'libone'
end
