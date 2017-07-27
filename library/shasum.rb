require_relative 'global.rb'
require_relative 'release.rb'

module Shasum

  FILE = "#{Global::BASE_DIR}/etc/shasums.txt"

  def self.read(qfn, release, platform_name)
    sums = read_file
    key = key(qfn, release, platform_name)
    sums[key]
  end

  def self.update(qfn, release, platform_name, shasum)
    sums = read_file
    key = key(qfn, release, platform_name)
    sums[key] = shasum
    write_file sums
  end

  # implementaion details

  def self.key(qfn, release, platform_name)
    "#{qfn} #{release} #{platform_name}"
  end

  def self.read_file
    sums = Hash.new('')
    File.exist?(FILE) and File.open(FILE) do |f|
      f.each_line do |line|
        qfn, release, platform_name, sum = line.split(' ')
        key = key(qfn, release, platform_name)
        sums[key] = sum
      end
    end
    sums
  end

  def self.write_file(sums)
    File.open(FILE, 'w') { |f| sums.each_pair { |key, sum| f.puts "#{key} #{sum}" } }
  end
end
