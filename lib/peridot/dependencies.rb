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

require 'peridot/platform_info'

module Peridot

  # Represents a dependency software that Passenger requires. It's used by the
  # installer to check whether all dependencies are available. A Dependency object
  # contains full information about a dependency, such as its name, code for
  # detecting whether it is installed, and installation instructions for the
  # current platform.
  class Dependency # :nodoc: all
    [:name, :install_command, :install_instructions, :install_comments,
     :website, :website_comments, :provides].each do |attr_name|
      attr_writer attr_name
      
      define_method(attr_name) do
        call_init_block
        return instance_variable_get("@#{attr_name}")
      end
    end
    
    def initialize(&block)
      @included_by = []
      @init_block = block
    end
    
    def define_checker(&block)
      @checker = block
    end
    
    def check
      call_init_block
      result = Result.new
      @checker.call(result)
      return result
    end

    def checks_command(command)
      self.define_checker do |result|
        path = PlatformInfo.find_command(command)
        if path
          result.found(path)
        else
          result.not_found
        end
      end
    end

    private
    class Result
      def found(*args)
        if args.empty?
          @found = true
        else
          @found = args.first
        end
      end
      
      def not_found
        found(false)
      end
      
      def found?
        return !@found.nil? && @found
      end
      
      def found_at
        if @found.is_a?(TrueClass) || @found.is_a?(FalseClass)
          return nil
        else
          return @found
        end
      end
    end

    def call_init_block
      if @init_block
        init_block = @init_block
        @init_block = nil
        init_block.call(self)
      end
    end
  end

  # Namespace which contains the different dependencies that Passenger may require.
  # See Dependency for more information.
  module Dependencies # :nodoc: all
    # Returns whether fastthread is a required dependency for the current
    # Ruby interpreter.
    def self.fastthread_required?
      return (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby") && RUBY_VERSION < "1.8.7"
    end

    # won't be needed for 'make dist' produced archive
    Automake = Dependency.new do |dep|
      dep.name = "GNU Automake"
      dep.checks_command 'automake'
      case PlatformInfo.linux_distro
      when :ubuntu, :debian
        dep.install_command = "apt-get install automake"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install automake"
      end
      dep.website = 'http://www.gnu.org/software/automake/'
    end

    # won't be needed for 'make dist' produced archive
    Autoconf = Dependency.new do |dep|
      dep.name = 'GNU Autoconf'
      dep.checks_command 'autoconf'
      case PlatformInfo.linux_distro
      when :ubuntu, :debian
        dep.install_command = "apt-get install autoconf"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install autoconf"
      end
      dep.website = 'http://www.gnu.org/software/autoconf/'
    end

    # won't be needed for 'make dist' produced archive
    Libtool = Dependency.new do |dep|
      dep.name = 'GNU Libtool'
      dep.checks_command 'libtool'
      case PlatformInfo.linux_distro
      when :ubuntu, :debian
        dep.install_command = "apt-get install libtool"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install libtool"
      end
      dep.website = 'http://www.gnu.org/software/libtool/'
    end

    # won't be needed for 'make dist' produced archive. Git is required for moxi build step that prepares version.m4.
    Git = Dependency.new do |dep|
      dep.name = 'Git revision control system'
      dep.define_checker do |result|
        path = PlatformInfo.find_command('git')
        if path
          result.found(path)
        else
          result.not_found
        end
      end
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install git-core"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install git-core"
        end
      end
      dep.website = "http://www.git-scm.org/"
    end

    LibeventDev = Dependency.new do |dep|
      dep.name = 'libevent'
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install libevent-dev"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install libevent-devel"
        end
      end
      dep.website = 'http://www.monkey.org/~provos/libevent/'
    end

    Check = Dependency.new do |dep|
      dep.name = 'Check: A unit testing framework for C'
      dep.define_checker do |result|
        if system('pkg-config check')
          result.found
        else
          result.not_found
        end
      end
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install check"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install check-devel"
        end
      end
      dep.website = 'http://check.sourceforge.net/'
    end

    SQLite3 = Dependency.new do |dep|
      dep.name = 'SQLite3'
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install libsqlite3-dev"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install sqlite-devel"
        end
      end
      dep.website = 'http://www.sqlite.org/'
    end

    Glib2 = Dependency.new do |dep|
      dep.name = 'GLib'
      dep.define_checker do |result|
        if system('pkg-config glib-2.0')
          result.found
        else
          result.not_found
        end
      end
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install libglib2.0-dev"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install glib2-devel"
        end
      end
      dep.website = 'http://check.sourceforge.net/'
    end

    LibSSL = Dependency.new do |dep|
      dep.name = 'OpenSSL headers'
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install libssl-dev"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install openssl-devel"
        end
      end
      dep.website = 'http://www.openssl.org/'
    end

    Make = Dependency.new do |dep|
      dep.name = 'Make'
      dep.define_checker do |result|
        path = PlatformInfo.find_command('make')
        if path
          result.found(path)
        else
          result.not_found
        end
      end
      if RUBY_PLATFORM =~ /linux/
        case PlatformInfo.linux_distro
        when :ubuntu, :debian
          dep.install_command = "apt-get install make"
        when :rhel, :fedora, :centos
          dep.install_command = "yum install make"
        end
      end
      dep.website = 'http://www.gnu.org/software/make/'
    end
  end

end # Peridot
