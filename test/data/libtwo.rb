class Libtwo < Package

  desc "Library Two"
  homepage "http://www.libtwo.org"

  release version: '1.1.0', crystax_version: 1
  release version: '2.2.0', crystax_version: 1

  depends_on 'libone'
end
