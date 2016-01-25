class Libthree < Library

  desc "Library Three"
  homepage "http://www.libthree.org"

  release version: '1.1.1', crystax_version: 1, sha256: '3b5316742df3db725a7cd99553c7cebe227e1b6f9f7e277c16476e512d1f1470'
  release version: '2.2.2', crystax_version: 1, sha256: '3b5316742df3db725a7cd99553c7cebe227e1b6f9f7e277c16476e512d1f1470'

  depends_on 'libone'
  depends_on 'libtwo'
end
