require 'fileutils'
require 'open3'


module Patch

  class FromData
    attr_reader :path

    def contents(path)
      data = ""
      File.open(path, "rb") do |f|
        begin
          line = f.gets
        end until line.nil? || /^__END__$/ === line
        data << line while line = f.gets
      end
      data
    end

    def apply(formula, src_dir)
      data = contents(formula.path)
      cmd = [Utils.patch_prog, '--strip=1', '--verbose', '-l']
      Open3.popen2e(*cmd, :chdir => src_dir) do |cin, cout, wt|
        output = ''
        it = Thread.start { cin.write(data); cin.close }
        ot = Thread.start { cout.read.split("\n").each { |l| output << l } }
        it.join
        ot.join
        rc = wt && wt.value.exitstatus
        raise "patch command failed with code: #{rc}; cmd: #{cmd}; output: #{output}" unless rc == 0
      end
    end
  end
end
