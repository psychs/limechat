# Copyright (c) 2007, The RubyCocoa Project.
# Copyright (c) 2005-2006, Jonathan Paisley.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

# Takes a built RubyCocoa app bundle (as produced by the 
# Xcode/ProjectBuilder template) and copies it into a new
# app bundle that has all dependencies resolved.
#
# usage:
#   ruby standaloneify.rb -d mystandaloneprog.app mybuiltprog.app
#
# This creates a new application that should have dependencies resolved.
#
# The script attempts to identify dependencies by running the program
# without OSX.NSApplicationMain, then grabbing the list of loaded
# ruby scripts and extensions. This means that only the libraries that
# you 'require' are bundled.
#
# NOTES:
#
#  Your ruby installation MUST NOT be the standard Panther install - 
#  the script depends on ruby libraries being in non-standard paths to
#  work.
#
#  I've only tested it with a DarwinPorts install of ruby 1.8.2.
#
#  Extension modules should be copied over correctly.
#
#  Ruby gems that are used are copied over in their entirety (thanks to some
#  ideas borrowed from rubyscript2exe)
#
#  install_name_tool is used to rewrite dyld load paths - this may not work
#  depending on how your libraries have been compiled. I've not had any 
#  issues with it yet though.
#
# Use ENV['RUBYCOCOA_STANDALONEIFYING?'] in your application to check if it's being standaloneified.

# FIXME: Using evaluation is "evil", should use RubyNode instead. Eloy Duran.

module Standaloneify
  MAGIC_ARGUMENT = '--standaloneify'

  def self.find_file_in_load_path(filename)
    return filename if filename[0] == ?/
      paths = $LOAD_PATH.select do |p|
      path = File.join(p,filename)
      return path if File.exist?(path)
      end
      return nil
  end

end

if __FILE__ == $0 and ARGV[0] == Standaloneify::MAGIC_ARGUMENT then
  # Got magic argument
  ARGV.shift

  module Standaloneify
    LOADED_FILES = []
    def self.notify_loaded(filename)
      LOADED_FILES << filename unless LOADED_FILES.include?(filename)
    end
  end

  module Kernel
    alias :pre_standaloneify_load :load
    def load(*args)
      if self.is_a?(OSX::OCObjWrapper) then
        return self.method_missing(:load,*args)
      end

      filename = args[0]
      result = pre_standaloneify_load(*args)
      Standaloneify.notify_loaded(filename) if filename and result
      return result
    end
  end

  module Standaloneify
    def self.find_files(loaded_features,loaded_files)

      loaded_features.delete("rubycocoa.bundle")

      files_and_paths = (loaded_features + loaded_files).map do |file|
        [file,find_file_in_load_path(file)]
      end

      files_and_paths.reject! { |f,p| p.nil? }

      if defined?(Gem) then
        resources_d = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
        gems_home_d = File.join(resources_d,"RubyGems")
        gems_gem_d = File.join(gems_home_d,"gems")
        gems_spec_d = File.join(gems_home_d,"specifications")

        FileUtils.mkdir_p(gems_spec_d)
        FileUtils.mkdir_p(gems_gem_d)

        Gem::Specification.list.each do |gem|
          next unless gem.loaded?
          $stderr.puts "Found gem #{gem.name}"

          FileUtils.cp_r(gem.full_gem_path,gems_gem_d)
          FileUtils.cp(File.join(gem.installation_path,"specifications",gem.full_name + ".gemspec"),gems_spec_d)
          # Remove any files that come from the GEM
          files_and_paths.reject! { |f,p| p.index(gem.full_gem_path) == 0 }
        end

        # Add basis RubyGems dependencies that are not detected since 
        # require is overwritten and doesn't modify $LOADED_FEATURES.
        %w{fileutils.rb etc.bundle}.each { |f| 
          files_and_paths << [f, find_file_in_load_path(f)] 
        }
      end

      return files_and_paths
    end
  end

  require 'osx/cocoa'

  module OSX
    def self.NSApplicationMain(*args)
      # Prevent application main loop from starting
    end
  end

  $LOADED_FEATURES << "rubycocoa.bundle"

  $0 = ARGV[0]
  require ARGV[0]

  loaded_features = $LOADED_FEATURES.uniq.dup
  loaded_files = Standaloneify::LOADED_FILES.dup

  require 'fileutils'

  result = Standaloneify.find_files(loaded_features, loaded_files)
  File.open(ENV["STANDALONEIFY_DUMP_FILE"],"w") {|fp| fp.write(result.inspect) }

  exit 0
end


module Standaloneify

  RB_MAIN_PREFIX = <<-EOT.gsub(/^ */,'')
  ################################################################################
  # #{File.basename(__FILE__)} patch
  ################################################################################
  # Remove all entries that aren't in the application bundle

  COCOA_APP_RESOURCES_DIR = File.dirname(__FILE__)

  $LOAD_PATH.reject! { |d| d.index(File.dirname(COCOA_APP_RESOURCES_DIR))!=0 }
  $LOAD_PATH << File.join(COCOA_APP_RESOURCES_DIR,"ThirdParty")
  $LOAD_PATH << File.join(File.dirname(COCOA_APP_RESOURCES_DIR),"lib")

  $LOADED_FEATURES << "rubycocoa.bundle"

  ENV['GEM_HOME'] = ENV['GEM_PATH'] = File.join(COCOA_APP_RESOURCES_DIR,"RubyGems")

  ################################################################################
  EOT

  def self.patch_main_rb(resources_d)
    rb_main = File.join(resources_d,"rb_main.rb")
    main_script = RB_MAIN_PREFIX + File.read(rb_main)
    File.open(rb_main,"w") do |fp|
      fp.write(main_script)
    end
  end

  def self.get_dependencies(macos_d,resources_d)
    # Set an environment variable that can be checked inside the application.
    # This is useful because standaloneify uses evaluation, so it might be possible
    # that the application does something which leads to problems while standaloneifying.
    ENV['RUBYCOCOA_STANDALONEIFYING?'] = 'true'
    
    dump_file = File.join(resources_d,"__require_dump")
    # Run the main Mac program
    mainprog = Dir[File.join(macos_d,"*")][0]
    ENV['STANDALONEIFY_DUMP_FILE'] = dump_file
    system(mainprog,__FILE__,MAGIC_ARGUMENT)

    begin
      result = eval(File.read(dump_file))
    rescue
      $stderr.puts "Couldn't read dependency list"
      exit 1
    end
    File.unlink(dump_file)        
    result
  end

  class LibraryFixer
    def initialize
      @done = {}
    end

    def self.needs_to_be_bundled(path)
      case path
      when %r:^/usr/lib/:
        return false
      when %r:^/lib/:
        return false
      when %r:^/Library/Frameworks:
        $stderr.puts "WARNING: don't know how to deal with frameworks (%s)" % path.inspect
        return false
      when %r:^/System/Library/Frameworks:
        return false
      when %r:^@executable_path:
        $stderr.puts "WARNING: can't handle library with existing @executable_path reference (%s)" % path.inspect
        return false
      end
      return true
    end

    ## For the given library, copy into the lib dir (if copy_self),
    ## iterate through dependent libraries and copy them if necessary,
    ## updating the name in self

    def fixup_library(relative_path,full_path,dest_root,copy_self=true)
      prefix = "@executable_path/../lib"

      lines = %x[otool -L '#{full_path}'].split("\n")
      paths = lines.map { |x| x.split[0] }
      paths.shift # argument name

      return if @done[full_path]

      if copy_self then
        @done[full_path] = true
        new_path = File.join(dest_root,relative_path)
        internal_path = File.join(prefix,relative_path)
        FileUtils.mkdir_p(File.dirname(new_path))
        FileUtils.cp(full_path,new_path)
        File.chmod(0700,new_path)
        full_path = new_path
        system("install_name_tool","-id",internal_path,new_path)
      end

      paths.each do |path|
        next if File.basename(path) == File.basename(full_path)

        if self.class.needs_to_be_bundled(path) then
          puts "Fixing %s in %s" % [path.inspect,full_path.inspect]
          fixup_library(File.basename(path),path,dest_root)

          lib_name = File.basename(path)
          new_path = File.join(dest_root,lib_name)
          internal_path = File.join(prefix,lib_name)

          system("install_name_tool","-change",path,internal_path,full_path)
        end
      end
    end
  end

  def self.make_standalone_application(source,dest,extra_libs)
    FileUtils.cp_r(source,dest)
    dest_d = Pathname.new(dest).realpath.to_s

    # Calculate various paths in new app bundle
    contents_d = File.join(dest_d,"Contents")
    frameworks_d = File.join(contents_d,"Frameworks")
    resources_d = File.join(contents_d,"Resources")
    lib_d = File.join(contents_d,"lib")
    macos_d = File.join(contents_d,"MacOS")

    # Calculate paths to the to-be copied RubyCocoa framework
    ruby_cocoa_d = File.join(frameworks_d,"RubyCocoa.framework")
    ruby_cocoa_inc = File.join(ruby_cocoa_d,"Resources","ruby")
    ruby_cocoa_lib = File.join(ruby_cocoa_d,"RubyCocoa")
    
    # First check if the developer might already have added the RubyCocoa framework (in a copy phase)
    unless File.exist? ruby_cocoa_d
      # Create Frameworks dir and copy RubyCocoa in there
      FileUtils.mkdir_p(frameworks_d)
      FileUtils.mkdir_p(lib_d)
      rc_path = [
        "/System/Library/Frameworks/RubyCocoa.framework",
        "/Library/Frameworks/RubyCocoa.framework"
      ].find { |p| File.exist?(p) }
      raise "Cannot locate RubyCocoa.framework" unless rc_path  
      # FileUtils.cp_r(rc_path,frameworks_d)
      # Do not use FileUtils.cp_r because it tries to follow symlinks.
      unless system("cp -R \"#{rc_path}\" \"#{frameworks_d}\"")
        raise "cannot copy #{rc_path} to #{frameworks_d}"
      end
    end

    # Copy in and update library references for RubyCocoa
    fixer = LibraryFixer.new
    fixer.fixup_library(File.basename(ruby_cocoa_lib),ruby_cocoa_lib,lib_d,false)

    third_party_d = File.join(resources_d,"ThirdParty")
    FileUtils.mkdir_p(third_party_d)

    # Calculate bundles and Ruby modules needed
    dependencies = get_dependencies(macos_d,resources_d)

    patch_main_rb(resources_d)

    extra_libs.each do |lib|
      dependencies << [lib,find_file_in_load_path(lib)]
    end

    dependencies.each do |feature,path|

      case feature
      when /\.rb$/
        next if feature[0] == ?/
        if File.exist?(File.join(ruby_cocoa_inc,feature)) then
        puts "Skipping RubyCocoa file " + feature.inspect
        next
        end
        if path[0..(resources_d.length - 1)] == resources_d
          puts "Skipping existing Resource file " + feature.inspect
          next
        end
        dir = File.join(third_party_d,File.dirname(feature))
        FileUtils.mkdir_p(dir)
        puts "Copying " + feature.inspect
        FileUtils.cp(path,File.join(dir,File.basename(feature)))

      when /\/rubycocoa.bundle$/
        next

      when /\.bundle$/
        puts "Copying bundle " + feature.inspect

        base = File.basename(path)
        if path then
          if feature[0] == ?/ then
            relative_path = File.basename(feature)
          else
            relative_path = feature
          end
          fixer.fixup_library(relative_path,path,lib_d)
        else
          puts "WARNING: Bundle #{extra} not found"
        end

      else
        $stderr.puts "WARNING: unknown feature %s loaded" % feature.inspect
      end
    end
  end

end

if $0 == __FILE__ then

  require 'ostruct'
  require 'optparse'
  require 'pathname'
  require 'fileutils'

  config = OpenStruct.new
  config.force = false
  config.extra_libs = []
  config.dest = nil

  ARGV.options do |opts|
    opts.banner = "usage: #{File.basename(__FILE__)} -d DEST [options] APPLICATION\n\nUse ENV['RUBYCOCOA_STANDALONEIFYING?'] in your application to check if it's being standaloneified.\n"
    opts.on("-f","--force","Delete target app if it exists already") { |config.force| }
    opts.on("-d DEST","--dest","Place result at DEST (required)") {|config.dest|}
    opts.on("-l LIBRARY","--lib","Extra library to bundle") { |lib| config.extra_libs << lib }

    opts.parse!
  end

  if not config.dest or ARGV.length!=1 then
    $stderr.puts ARGV.options
    exit 1
  end

  source_app_d = ARGV.shift

  if config.dest !~ /\.app$/ then
    $stderr.puts "Target must have '.app' extension"
    exit 1
  end

  if File.exist?(config.dest) then
    if config.force then
      FileUtils.rm_rf(config.dest)
    else
      $stderr.puts "Target exists already (#{config.dest.inspect})"
      exit 1
    end
  end

  Standaloneify.make_standalone_application(source_app_d,config.dest,config.extra_libs)

end

