#
# Portions Copyright (c) 2009, NorthScale
#
module Peridot
  module UtilsMixin
    def sh(*args)
      puts "# #{args.join(' ')}"
      result = system(*args)
      if result
        return true
      elsif $?.signaled? && $?.termsig == Signal.list["INT"]
        raise Interrupt
      else
        return false
      end
    end

    def continue_or_not
      color_puts "<b>Press Enter to continue, or Ctrl-C to abort.</b>"
      wait
    end

    def reset_terminal_colors
      STDOUT.write("\e[0m")
      STDOUT.flush
    end
    
    def color_print(text)
      STDOUT.write(ConsoleTextTemplate.new(:text => text).result)
      STDOUT.flush
    end
    
    def color_puts(text)
      color_print("#{text}\n")
    end
    
    def render_template(name, options = {})
      puts ConsoleTextTemplate.new({ :file => name }, options).result
    end
    
    def new_screen
      puts
      line
      puts
    end
    
    def line
      puts "--------------------------------------------"
    end
    
    def prompt(message)
      done = false
      while !done
        color_print "#{message}: "
        begin
          result = STDIN.readline
        rescue EOFError
          exit 2
        end
        result.strip!
        done = !block_given? || yield(result)
      end
      return result
    rescue Interrupt
      exit 2
    end
    
    def wait(timeout = nil)
      return if @auto
      begin
        if timeout
          require 'timeout' unless defined?(Timeout)
          begin
            Timeout.timeout(timeout) do
              STDIN.readline
            end
          rescue Timeout::Error
            # Do nothing.
          end
        else
          STDIN.readline
        end
      rescue Interrupt
        exit 2
      end
    end
  end
end
