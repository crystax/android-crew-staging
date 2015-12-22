class Icu4c < Library

  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "http://site.icu-project.org/"
  url "https://ssl.icu-project.org/files/icu4c/${version}/icu4c-${block}-src.tgz" do |v| v.gsub('.', '_') end

  release version: '56.1', crystax_version: 1, sha256: '0'
end
