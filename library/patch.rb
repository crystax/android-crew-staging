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

    def apply(formula, src_dir, log_file)
      data = contents(formula.path)
      cmd = [Utils.patch_prog, '--strip=1']
      File.open(log_file, "a") do |log|
        log.puts "== cmd started: #{cmd.join(' ')}"
        rc = 0
        Open3.popen2e(*cmd, :chdir => src_dir) do |cin, cout, wt|
          it = Thread.start { cin.write(data) ; cin.close }
          ot = Thread.start { cout.read.split("\n").each { |l| log.puts l } }
          it.join
          ot.join
          rc = wt && wt.value.exitstatus
        end
        log.puts "== cmd finished: exit code: #{rc} cmd: #{cmd}"
        raise "command failed with code: #{rc}; see #{log_file} for details" unless rc == 0
      end
    end
  end
end
