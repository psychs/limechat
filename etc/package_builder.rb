require 'fileutils'

class PackageBuilder
  
  attr_accessor :name
  
  def self.build(path)
    raise "Path `#{path}' does not exist" unless File.exist?(path)
    raise "Path `#{path}' is not an application bundle" unless File.extname(path) == '.app'
    
    build = new
    Dir.chdir(File.dirname(path)) do
      build.name = File.basename(path, '.app') 
      build.build
    end
  end
  
  def build
    unless File.exist?(File.join(frameworks_root, 'RubyCocoa.framework'))
      FileUtils.mkdir_p frameworks_root
      Dir.chdir(frameworks_root) do
        `tar xzvf #{framework_package}`
      end
    end
    `install_name_tool -change /System/Library/Frameworks/RubyCocoa.framework/Versions/A/RubyCocoa @executable_path/../Frameworks/RubyCocoa.framework/Versions/A/RubyCocoa '#{macos_root}/#{objective_c_executable_file}'`
    `install_name_tool -change /Library/Frameworks/RubyCocoa.framework/Versions/A/RubyCocoa @executable_path/../Frameworks/RubyCocoa.framework/Versions/A/RubyCocoa '#{macos_root}/#{objective_c_executable_file}'`
  end

  def objective_c_executable_file
    name
  end

  def bundle_root
    "#{name}.app"
  end
  
  def contents_root
    File.join(bundle_root, "Contents")
  end

  def frameworks_root
    File.join(contents_root, "Frameworks")
  end
  
  def macos_root
    File.join(contents_root, "MacOS")
  end
  
  def framework_package
    "../../../../../resource/rubycocoa/RubyCocoa_0.13.2.2_10.5.tar.gz"
  end

end
