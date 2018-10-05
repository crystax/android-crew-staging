class Libfive < Package

  desc "Library Five"
  homepage "http://www.libfive.org"

  release '1.1.0'

  depends_on 'libfour', version: /^1\.1/
end
