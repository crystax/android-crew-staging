require 'io/console'

module Crew

  class ProgressBar

    def initialize(title = '')
      _rows, cols = IO.console.winsize

      @stdout_sync = $stdout_sync

      @title = title
      @max_num = cols - 2 - title.size
      @per_percent = @max_num.to_f / 100

      # debug
      # puts "cols:           #{cols}"
      # puts "@max_num:       #{@max_num}"
      # puts "@per_percent:   #{@per_percent}"
      # puts ''

      @percents_done = 0
      @outputted = 0

      self.start
    end

    def percents_done(n)
      # debug
      # puts "n:              #{n}"
      # puts "@percents_done: #{@percents_done}"
      # puts "@outputted:     #{@outputted}"

      raise "bad percent value: #{n}" if (n < 0) || (n > 100)

      self.reset if @percents_done >= 100

      raise "percents done: #{@percents_done} is more then new value: #{n}" if n < @percents_done

      inc = ((n - @percents_done) * @per_percent).to_i
      @percents_done = n
      if @percents_done >= 100
        inc = @max_num - @outputted
      end

      (1..inc).each { $stdout << '#' }
      @outputted += inc

      # debug
      # puts "inc:            #{inc}"
      # puts "@percents_done: #{@percents_done}"
      # puts "@outputted:     #{@outputted}"
      # puts ''
    end

    def start
      $stdout.sync = true
      print @title
    end

    def stop
      puts ''
      $stdout.sync = @stdout_sync
    end

    def reset
      @percents_done = 0
      @outputted = 0

      $stdout << "\r" << @title
      (1..@max_num).each { $stdout << ' ' }
      $stdout << "\r"

      self.start
    end
  end

  class NumProgressBar

    def initialize(max_num, title = '')
      raise ArgumentError, "bad 'max_num' value: #{num}; must be a natural number" if max_num < 1

      _rows, cols = IO.console.winsize
      @stdout_sync = $stdout_sync

      @title = title
      @max_num = max_num
      @max_hashes = cols - 2 - title.size
      @per_hash = (@max_num.to_f / @max_hashes).ceil

      @cur_num = 0
      @outputted = 0

      # debug:
      # puts "cols:       #{cols}"
      # puts "max_num:    #{@max_num}"
      # puts "max_hashes: #{@max_hashes}"
      # puts "per_hash:   #{@per_hash}"
    end

    def start
      $stdout.sync = true
      $stdout << @title
    end

    def plus_one
      @cur_num += 1

      # debug:
      # puts "cur_num:            #{@curnum}"
      # puts "cur_num % per_hash: #{@cur_num % @per_hash}"
      # puts "outputted:          #{@outputted}"

      if ((@cur_num % @per_hash) == 0) && (@outputted < @max_hashes)
        $stdout << '#'
        @outputted += 1
      end

      # debug:
      # puts "outputted:          #{@outputted}"
    end

    def stop
      # print the rest
      (1..@max_hashes-@outputted).to_a.each { $stdout << '#' }
      $stdout << "\n"

      # debug:
      # puts "cur_num:   #{@cur_num}"
      # puts "outputted: #{@outputted}"

      $stdout.sync = @stdout_sync
    end
  end
end
