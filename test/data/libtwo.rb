class Libtwo < Package

  desc "Library Two"
  homepage "http://www.libtwo.org"

  release version: '1.1.0', crystax_version: 1, sha256: 'd3e8662c117ac67c10925b8dd3f0bce0717ad0be3a9d103c06abbe959804a0ff'
  release version: '2.2.0', crystax_version: 1, sha256: 'd3e8662c117ac67c10925b8dd3f0bce0717ad0be3a9d103c06abbe959804a0ff'

  depends_on 'libone'
end
