# The following has been used with permission from Phusion Passenger
# Portions Copyright (c) 2009, NorthScale
# ---------------------------------------------------------------------------
#
#  Phusion Passenger - http://www.modrails.com/
#  Copyright (c) 2008, 2009 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

require 'rbconfig'

module Peridot
  module PlatformInfo
    private
    # Turn the specified class method into a memoized one. If the given
    # class method is called without arguments, then its result will be
    # memoized, frozen, and returned upon subsequent calls without arguments.
    # Calls with arguments are never memoized.
    #
    #   def self.foo(max = 10)
    #      return rand(max)
    #   end
    #   memoize :foo
    #   
    #   foo   # => 3
    #   foo   # => 3
    #   foo(100)   # => 49
    #   foo(100)   # => 26
    #   foo   # => 3
    def self.memoize(method)
      metaclass = class << self; self; end
      metaclass.send(:alias_method, "_unmemoized_#{method}", method)
      variable_name = "@@memoized_#{method}".sub(/\?/, '')
      check_variable_name = "@@has_memoized_#{method}".sub(/\?/, '')
      eval("#{variable_name} = nil")
      eval("#{check_variable_name} = false")
      source = %Q{
        	   def self.#{method}(*args)                                # def self.httpd(*args)
                       if args.empty?                                        #    if args.empty?
        	         if !#{check_variable_name}                         #       if !@@has_memoized_httpd
                           #{variable_name} = _unmemoized_#{method}.freeze #          @@memoized_httpd = _unmemoized_httpd.freeze
                           #{check_variable_name} = true                   #          @@has_memoized_httpd = true
        	         end                                                #       end
        	         return #{variable_name}                            #       return @@memoized_httpd
                       else                                                  #    else
        	         return _unmemoized_#{method}(*args)                #       return _unmemoized_httpd(*args)
                       end                                                   #    end
        	   end                                                      # end
                 }
      class_eval(source)
    end
    
    def self.env_defined?(name)
      return !ENV[name].nil? && !ENV[name].empty?
    end
    
    def self.locate_ruby_executable(name)
      if RUBY_PLATFORM =~ /darwin/ &&
          RUBY =~ %r(\A/System/Library/Frameworks/Ruby.framework/Versions/.*?/usr/bin/ruby\Z)
        # On OS X we must look for Ruby binaries in /usr/bin.
        # RubyGems puts executables (e.g. 'rake') in there, not in
        # /System/Libraries/(...)/bin.
        filename = "/usr/bin/#{name}"
      else
        filename = File.dirname(RUBY) + "/#{name}"
      end
      if File.file?(filename) && File.executable?(filename)
        return filename
      else
        # RubyGems might put binaries in a directory other
        # than Ruby's bindir. Debian packaged RubyGems and
        # DebGem packaged RubyGems are the prime examples.
        begin
          require 'rubygems' unless defined?(Gem)
          filename = Gem.bindir + "/#{name}"
          if File.file?(filename) && File.executable?(filename)
            return filename
          else
            return nil
          end
        rescue LoadError
          return nil
        end
      end
    end
    
    # Look in the directory +dir+ and check whether there's an executable
    # whose base name is equal to one of the elements in +possible_names+.
    # If so, returns the full filename. If not, returns nil.
    def self.select_executable(dir, *possible_names)
      possible_names.each do |name|
        filename = "#{dir}/#{name}"
        if File.file?(filename) && File.executable?(filename)
          return filename
        end
      end
      return nil
    end

    def self.read_file(filename)
      return File.read(filename)
    rescue
      return ""
    end

    public
    # The absolute path to the current Ruby interpreter.
    RUBY = Config::CONFIG['bindir'] + '/' + Config::CONFIG['RUBY_INSTALL_NAME'] + Config::CONFIG['EXEEXT']
    # The correct 'gem' command for this Ruby interpreter.
    GEM = locate_ruby_executable('gem')
    
    # Check whether the specified command is in $PATH, and return its
    # absolute filename. Returns nil if the command is not found.
    #
    # This function exists because system('which') doesn't always behave
    # correctly, for some weird reason.
    def self.find_command(name)
      ENV['PATH'].split(File::PATH_SEPARATOR).detect do |directory|
        path = File.join(directory, name.to_s)
        if File.executable?(path)
          return path
        end
      end
      return nil
    end
    
    
    # The current platform's shared library extension ('so' on most Unices).
    def self.library_extension
      if RUBY_PLATFORM =~ /darwin/
        return "bundle"
      else
        return "so"
      end
    end
    
    # An identifier for the current Linux distribution. nil if the operating system is not Linux.
    def self.linux_distro
      if RUBY_PLATFORM !~ /linux/
        return nil
      end
      lsb_release = read_file("/etc/lsb-release")
      if lsb_release =~ /Ubuntu/
        return :ubuntu
      elsif File.exist?("/etc/debian_version")
        return :debian
      elsif File.exist?("/etc/redhat-release")
        redhat_release = read_file("/etc/redhat-release")
        if redhat_release =~ /CentOS/
          return :centos
        elsif redhat_release =~ /Fedora/  # is this correct?
          return :fedora
        else
          # On official RHEL distros, the content is in the form of
          # "Red Hat Enterprise Linux Server release 5.1 (Tikanga)"
          return :rhel
        end
      elsif File.exist?("/etc/suse-release")
        return :suse
      elsif File.exist?("/etc/gentoo-release")
        return :gentoo
      else
        return :unknown
      end
      # TODO: Slackware, Mandrake/Mandriva
    end
    memoize :linux_distro
  end
end
