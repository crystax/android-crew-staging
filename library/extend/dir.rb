class Dir
  def self.empty?(path)
    Dir.exist?(path) and (Dir["#{path}/*", "#{path}/.*"] - ['.', '..']).empty?
  end
end
