class Sqlite < Library

  desc "SQLite library"
  homepage "https://sqlite.org/"
  url "https://sqlite.org/2015/sqlite-amalgamation-${block}.zip" do |v| ('%-2s%-2s%-3s' % v.split('.')).gsub(' ', '0') end

  release version: '3.9.2', crystax_version: 1, sha256: '0'
end
