require 'osx/cocoa'

module SAFoundation
  module OS
    def self.host_name
      `hostname`.chomp
    end
    
    # Returns the OS version.
    def self.os_version
      os_version_and_build.first
    end
  
    # Returns the OS build number.
    def self.os_build
      os_version_and_build.last
    end
    
    private
    
    def self.os_version_and_build
      @@__os_version ||= `/usr/bin/sw_vers`.scan(/ProductVersion:\t([\d\w\.]+)\nBuildVersion:\t([\d\w\.]+)/).first
    end
  end
end

class SACrashReporter < OSX::NSWindowController
  class Report
    attr_accessor :exception
    
    # Calls the specified method and returns an array.
    # The first element contains the key as it should show up in the report,
    # so for instance: 'Host Name:'
    # And the second element contains the actual result.
    #
    # If a method is called through +get+ and it returns anything other than an array
    # the key will be created from the method name. Eg: :host_name => 'Host Name:'
    # If you more control over the key, simply return an array with the correct key and result.
    #
    # Please note that most of the predefined methods expect to be called through this method.
    def get(name)
      result = self.send(name)
      if result.is_a? Array
        result
      else
        [name.to_s.split('_').map { |e| e.capitalize }.join(' ') << ':', result]
      end
    end
    
    # Returns the machine's hostname: ["Host Name:", "macbook.local"]
    def host_name
      `hostname`.chomp
    end
    
    # Returns the date/time: ["Date/Time:", "Fri Oct 12 15:16:28 +0200 2007"]
    def date_time
      ['Date/Time:', Time.now.to_s]
    end
    
    # Returns the os version: ["OS Version:", "10.4.10 (8R2232)"]
    def os_version
      ['OS Version:', "#{SAFoundation::OS.os_version} (#{SAFoundation::OS.os_build})"]
    end
    
    # Returns the SACrashReporter version: ["Report Version:", "SACrashReporter version 1"]
    def report_version
      "SACrashReporter version #{SACrashReporter::VERSION}"
    end
    
    # Returns the Ruby intepreter version
    def ruby_version
      "Ruby version: #{RUBY_VERSION}"
    end
    
    # Returns the RubyCocoa version
    def rubycocoa_version
      "RubyCocoa version: #{OSX::RUBYCOCOA_VERSION}"
    end
    
    # Returns the application executable: ["Command:", "MyApp"]
    def command
      OSX::NSBundle.mainBundle.infoDictionary['CFBundleExecutable'].to_s
    end
    
    # Returns the full path to the executable: ["Path:", "/Applications/Foo.app/Contents/MacOS/Foo"]
    def path
      OSX::NSBundle.mainBundle.executablePath.fileSystemRepresentation.to_s
    end
    
    # Returns the application's short version and the version: ["Version:", "1.0 final (1.0)"]
    def version
      app_info_plist = OSX::NSBundle.mainBundle.infoDictionary
      "#{app_info_plist['CFBundleShortVersionString']} (#{app_info_plist['CFBundleVersion']})"
    end
    
    # Returns the process id (pid) of the application: ["PID:", "10999"]
    def pid
      ['PID:', OSX::NSProcessInfo.processInfo.processIdentifier.to_s]
    end
    
    # Sets the order that the message will be rendered in.
    # Use it to specify which logs will be used and group them together for nicer layouts.
    #
    #   report.order = [[:host_name], [:os_version, :pid]]
    #   report.message
    #
    # Results in:
    #
    #  **********
    # 
    #   Host Name: supermachine.local
    # 
    #  OS Version: 10.4.10 (8R2232)
    #         PID: 10999
    #
    #   Exception: Some random error.
    #
    #  BACKTRACE:
    #  ...
    def order=(*order)
      @order = (order.length == 1 ? order.first : order) unless order.empty?
    end
    
    # Returns the current order.
    #
    #   report.order #=> [[:host_name], [:os_version, :pid]]
    def order
      @order
    end
    
    # Returns a string which contains the rendered message.
    # Control the output by setting the +order+.
    def message
      logs = ordered_logs
      longest_key = logs.flatten.inject(0) { |count, key| count < key.to_s.length ? key.to_s.length : count }.next
      "\n\n**********\n\n" << logs.map { |keys| render_section(keys, longest_key) }.join << error_and_bt(longest_key)
    end
    
    private
    
    # The default layout of an Apple crash log
    # DEFAULT_APPLE_STYLE_CRASH_LOG = [[:host_name, :date_time, :os_version, :report_version], [:command, :path], [:version], [:pid]]
    DEFAULT_APPLE_STYLE_CRASH_LOG = [[:host_name, :date_time, :os_version, :ruby_version, :rubycocoa_version, :report_version], [:command, :path], [:version], [:pid]]
    def ordered_logs
      @order || DEFAULT_APPLE_STYLE_CRASH_LOG
    end
    
    WHITESPACE = '                                                                ' #:nodoc:
    def whitespace(count)
      WHITESPACE[0...(count - 1)]
    end
    
    def error_and_bt(longest_key)
      whitespace(longest_key - 9) << "Exception: #{@exception}\n\nBACKTRACE:\n" << @exception.backtrace.join("\n")
    end
    
    def render_section(keys, longest_key)
      keys.map { |key| whitespace(longest_key - key.to_s.length) << self.get(key).join(' ') }.join("\n") << "\n\n"
    end
  end
end