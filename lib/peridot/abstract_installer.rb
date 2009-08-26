# The following has been used with permission from Phusion Passenger
# Portions Copyright (c) 2009, NorthScale
# ----------------------------------------------------------------------------
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

# require 'phusion_passenger/constants'
# require 'phusion_passenger/packaging'
require 'peridot/console_text_template'

module Peridot

  # Abstract base class for installers. Used by passenger-install-apache2-module
  # and passenger-install-nginx-module.
  class AbstractInstaller
    include Peridot::UtilsMixin

    def initialize(options = {})
      options.each_pair do |key, value|
        instance_variable_set(:"@#{key}", value)
      end
    end
    
    def start
      install!
    ensure
      reset_terminal_colors
    end

    private
    def dependencies
      return []
    end
    
    def check_dependencies
      new_screen
      missing_dependencies = []
      color_puts "<banner>Checking for required software...</banner>"
      puts
      dependencies.each do |dep|
        color_print " * #{dep.name}... "
        result = dep.check
        if result.found?
          if result.found_at
            color_puts "<green>found at #{result.found_at}</green>"
          else
            color_puts "<green>found</green>"
          end
        else
          color_puts "<red>not found</red>"
          missing_dependencies << dep
        end
      end
      
      if missing_dependencies.empty?
        return true
      else
        puts
        color_puts "<red>Some required software is not installed.</red>"
        color_puts "But don't worry, this installer will tell you how to install them.\n"
        continue_or_not
        
        line
        puts
        color_puts "<banner>Installation instructions for required software</banner>"
        puts
        missing_dependencies.each do |dep|
          print_dependency_installation_instructions(dep)
          puts
        end
        return false
      end
    end
    
    def print_dependency_installation_instructions(dep)
      color_puts " * To install <yellow>#{dep.name}</yellow>:"
      if !dep.install_command.nil?
        color_puts "   Please run <b>#{dep.install_command}</b> as root."
      elsif !dep.install_instructions.nil?
        color_puts "   " << dep.install_instructions
      elsif !dep.website.nil?
        color_puts "   Please download it from <b>#{dep.website}</b>"
        if !dep.website_comments.nil?
          color_puts "   (#{dep.website_comments})"
        end
      else
        color_puts "   Search Google."
      end
    end
  end
end
