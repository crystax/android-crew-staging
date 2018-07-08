class Libthree < Package

  desc "Library Three"
  homepage "http://www.libthree.org"

  release '1.1.1', crystax: 2
  release '2.2.2', crystax: 1

  depends_on 'libone'
  depends_on 'libtwo'
end
