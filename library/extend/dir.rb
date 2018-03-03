class Dir
  def self.empty?(path)
    Dir.exist?(path) and (Dir["#{path}/*", "#{path}/.*"] - ['.', '..']).empty?
  end

  def self.size(path)
    Dir["#{path}/**/*", "#{path}/**/.*"].map { |f| File.size(f) }.inject(0, :+)
  end
end
