#!/usr/bin/env ruby
# Copyright (c) 2006-2007, The RubyCocoa Project.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'rbconfig'

def show_options
  puts "Usage:"
  puts "  #{__FILE__} build [options] <output dir>"
  puts ""
  puts "  build  Create the RDoc documentation for the supported frameworks"
  puts ''
  puts "Options:"
  puts "  The extra options only apply to 'build' option and are options passed"
  puts "  to the actual rdocify_framework.rb script."
  puts "  These are:"
  puts "  -v Verbose output."
  puts "  -f Force the output files to be written even if there were errors during parsing."
  puts ''
  puts "Output Dir:"
  puts "  If a optional output dir is specified,"
  puts "  the documentation will be generated in that location."
  puts ""
  puts "Examples:"
  puts "  #{__FILE__} build ~/documentation"
  puts "  #{__FILE__} build -v -f"
  puts ''
end

def command( str )
  $stderr.puts str
  system str or raise RuntimeError, "'system #{str}' failed"
end

def ruby( str )
  command "#{Config::CONFIG["bindir"]}/ruby #{str}"
end

def rdoc( str )
  command "#{Config::CONFIG["bindir"]}/rdoc #{str}"
end

unless ARGV[0].nil?
  case ARGV[0]
  when 'build'
    options = []
    output_dir = ''
    
    # Check if there are any other args
    if ARGV.length > 1
      ARGV[1..-1].each do |arg|
        case arg
        when '-v'
          options.push '-v'
        when '-f'
          options.push '-f'
        else
          output_dir = arg
        end
      end
    end
    
    # Get a reference to the output dir and create it if necessary
    unless output_dir.empty?
      output_dir = File.expand_path(output_dir)
      unless File.exist?(output_dir)
        command "mkdir -p #{output_dir}"
      end
    else
      output_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'doc/')
    end
    
    DOCUMENTATION_PATH =
      if `sw_vers -productVersion`.strip =~ /^10\.5/
        '/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation'
      else
        '/Developer/ADC Reference Library/documentation'
      end
    SUPPORTED_FRAMEWORKS = ["#{DOCUMENTATION_PATH}/Cocoa/Reference/ApplicationKit/",
                            "#{DOCUMENTATION_PATH}/Cocoa/Reference/Foundation/",
                            "#{DOCUMENTATION_PATH}/Cocoa/Reference/WebKit/",
                            "#{DOCUMENTATION_PATH}/Cocoa/Reference/CoreDataFramework/",
                            "#{DOCUMENTATION_PATH}/QuickTime/Reference/QTKitFramework/",
                            "#{DOCUMENTATION_PATH}/UserExperience/Reference/AddressBook/",
                            "#{DOCUMENTATION_PATH}/AppleApplications/Reference/InstantMessageFrameworkRef/",
                            "#{DOCUMENTATION_PATH}/GraphicsImaging/Reference/QuartzFramework/"]

    start_time = Time.now
    
    # Setup the env
    ENV['DYLD_FRAMEWORK_PATH'] = File.expand_path('../build/Default')
    ENV['BRIDGE_SUPPORT_PATH'] = File.expand_path('../bridge-support')
    
    # Parse the rdoc for each supported framework
    SUPPORTED_FRAMEWORKS.each do |f|
      ruby "-I../../ext/rubycocoa -I../../lib gen_bridge_doc/rdocify_framework.rb #{options.join(' ')} '#{f}' #{output_dir}/ruby"
    end
    
    osx_additions = %w{oc_attachments.rb oc_attachments_appkit.rb oc_types.rb oc_types_appkit.rb ruby_addition.rb}.map do |file|
      File.expand_path(file, '../src/ruby/osx/objc/')
    end.join(' ')
    
    # Create the rdoc files
    #system "rdoc  --line-numbers --inline-source --template gen_bridge_doc/allison/allison.rb gen_bridge_doc/output -o doc/html"
    Dir.chdir "#{output_dir}/ruby" do
      rdoc ". -o #{output_dir}/html #{osx_additions}"
      rdoc "--ri . -o #{output_dir}/ri #{osx_additions}"
    end
    
    puts ""
    puts "Total Cocoa Reference to RDoc processing time: #{Time.now - start_time} seconds"
  else
    show_options
    exit 1
  end
else
  show_options
  exit 1
end
