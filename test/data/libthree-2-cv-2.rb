class Libthree < Package

  desc "Library Three"
  homepage "http://www.libthree.org"

  release version: '1.1.1', crystax_version: 2
  release version: '2.2.2', crystax_version: 1

  depends_on 'libone'
  depends_on 'libtwo'
end
