require 'osx/cocoa'
require 'net/http'
require 'cgi'

require File.expand_path('../Report', __FILE__)

class SACrashReporter < OSX::NSWindowController
  
  VERSION = 1.1
  
  # tmp fix for HDCrashReporter that crashes if there's no crash log, but there are traces in the prefs(?).
  #`touch #{File.expand_path("~/Library/Logs/CrashReporter/Crasher.crash.log")}`
  
  # Returns the report instance.
  def self.report
    @@report ||= Report.new
  end
  
  # Configure the report layout.
  # +configure+ will yield the report instance on which you can then call +order+.
  # You can optionally specify the subclass of +Report+ to use.
  #
  #   class ReportSubclass < SACrashReporter::Report
  #     def my_custom_log_1
  #       'foo'
  #     end
  #     def my_custom_log_2
  #       'bar'
  #     end
  #   end
  #
  #   SACrashReporter.configure :report_class => ReportSubclass do |report|
  #     report.order [:host_name], [:my_custom_log_1, :my_custom_log_2], [:os_version, :pid]
  #   end
  def self.configure(options = {:report_class => Report})
    @@report = options[:report_class].new
    yield report
  end
  
  # Call this method from your rb_main.rb file to start the ruby exception catching.
  # If you don't need any customisation you can simply replace the code that starts the
  # app by +run_app+ like so:
  #
  #  # rb_main.rb:
  #
  #  def rb_main_init
  #    path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  #    rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  #    rbfiles -= [ File.basename(__FILE__) ]
  #    rbfiles.each do |path|
  #      require( File.basename(path) )
  #    end
  #  end
  #
  #  # if $0 == __FILE__ then
  #  #   rb_main_init
  #  #   OSX.NSApplicationMain(0, nil)
  #  # end
  #
  #  SACrashReporter.run_app
  #
  # If you need custom code to start the application you can specify it in a block passed
  # to +run_app+. Please note that you are then also responsible for starting the app with <tt>OSX.NSApplicationMain()</tt>.
  #
  #  SACrashReporter.run_app do
  #    # some special startup code
  #    OSX.NSApplicationMain(0, nil)
  #  end
  #
  # See the +configure+ method if you want to set any SACrashReporter/Report options.
  def self.run_app
    begin
      if block_given?
        yield
      else
        # Run the normal RubyCocoa init.
        rb_main_init
        OSX.NSApplicationMain(0, nil)
      end
    rescue Exception => exception
      # write backtrace to crash log so it can be reported on next launch
      report.exception = exception
      File.open(new_crash_log_path, "a") { |file| file.write report.message }
      # re-raise the exception
      raise exception
    end
  end
  
  # Returns the name of the application.
  def self.app_name
    OSX::NSBundle.mainBundle.infoDictionary['CFBundleExecutable']
  end
  
  # Returns the name of the developer, which is retrieved from the Info.plist with key 'SACrashReporterDeveloperName'.
  def self.developer
    OSX::NSBundle.mainBundle.infoDictionary['SACrashReporterDeveloperName']
  end
  
  # Returns the full path to the crash log for the current application.
  def self.crash_log_path
    return @@crash_log_path if defined? @@crash_log_path
    
    crash_log_dir = File.expand_path("~/Library/Logs/CrashReporter/")
    log_files = Dir.entries(crash_log_dir).select {|f| f[0..(app_name.length - 1)] == app_name } rescue []
    return new_crash_log_path if log_files.empty?
    
    @@crash_log_path = File.join(crash_log_dir, log_files.sort.last)
    @@crash_log_path
  end
  
  def self.new_crash_log_path
    if SAFoundation::OS.os_version.to_f < 10.5
      File.expand_path("~/Library/Logs/CrashReporter/#{app_name}.crash.log")
    else
      time = Time.now
      time_str = format("%02d-%02d-%02d_%02d%02d%02d", time.year, time.month, time.day, time.hour, time.min, time.sec)
      File.expand_path("~/Library/Logs/CrashReporter/#{app_name}_#{time_str}_#{SAFoundation::OS.host_name.sub(/\.(\w)+$/, '')}.crash")
    end
  end
  
  # Returns the SHA1 checksum for the crash log of the current application.
  def self.crash_log_checksum
    @@crash_log_checksum ||= `/usr/bin/openssl sha1 #{crash_log_path}`.scan(/\)=\s([a-z0-9]+)\n$/)[0][0]
  end
  
  # Returns +true+ or +false+ depending on if the crash log for the current application exists.
  def self.new_crash_log_exists?
    return false unless File.exist? crash_log_path
    last_checksum = OSX::NSUserDefaults.standardUserDefaults['SACrashReporterLastCheckSum']
    last_checksum.nil? or crash_log_checksum != last_checksum
  end
  
  # Returns the last entrie of the crash log for the current application.
  def self.crash_log_data
    @@crash_log_data ||= File.read(crash_log_path).split('**********').last.sub(/^\n*/, '').chomp
  end
  
  # This method should called from somewhere in your code where the application has started.
  #
  #   class AppController < OSX::NSObject
  #     def awakeFromNib
  #       SACrashReporter.submit
  #     end
  #   end
  def self.submit
    defaults = OSX::NSUserDefaults.standardUserDefaults
    unless defaults['SACrashReporterInitialized']
      defaults['SACrashReporterInitialized'] = true
      if new_crash_log_exists?
       defaults['SACrashReporterLastCheckSum'] = crash_log_checksum
      end
      defaults.synchronize
    else
      if new_crash_log_exists?
       @@crash_reporter_controller = SACrashReporter.alloc.init
       @@crash_reporter_controller.showWindow(self)
       defaults['SACrashReporterLastCheckSum'] = crash_log_checksum
       defaults.synchronize
      end
    end
  end
  
  # Instance methods
  
  ib_outlet :crashLogDataTextfield
  ib_outlet :commentTextfield
  ib_outlet :footnoteTextfield
  ib_outlet :sendReportButton
  ib_outlet :statusSpinner
  ib_outlet :statusTextField
  
  def init
    return self if self.initWithWindowNibPath_owner(File.expand_path('../SACrashReporter.nib', __FILE__), self)
  end
  
  def windowDidLoad
    set_title_for_app
    set_footnote_text_with_dev
    set_button_text_with_dev
    @crashLogDataTextfield.string = SACrashReporter.crash_log_data
  end
  
  def set_title_for_app
    window.title = "Problem Report for #{SACrashReporter.app_name}"
  end
  
  def set_footnote_text_with_dev
    @footnoteTextfield.stringValue = "Your report will help #{SACrashReporter.developer} improve this software. Your personal information is not sent with this report. You will not be contacted in response to this report unless you would like to in which case please leave your contact info in the comment."
  end
  
  def set_button_text_with_dev
    @sendReportButton.title = "Send to #{SACrashReporter.developer}..."
  end
  
  def sendReport(sender)
    @statusTextField.hidden = false
    @statusSpinner.startAnimation(self)
    
    params_hash = {
     'app_name' => SACrashReporter.app_name,
     'crash_log' => SACrashReporter.crash_log_data,
     'comment' => @commentTextfield.string
    }
    params = params_hash.inject('') {|v,i| v << "#{i[0].to_s}=#{CGI.escape(i[1].to_s)}&"}.chop
    params_data = OSX::NSString.stringWithString(params).dataUsingEncoding(OSX::NSASCIIStringEncoding)
    
    url = OSX::NSURL.URLWithString(OSX::NSBundle.mainBundle.infoDictionary['SACrashReporterPostURL'])
    
    request = OSX::NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, OSX::NSURLRequestUseProtocolCachePolicy, 30.0)
    request.setHTTPMethod('POST')
    request.setHTTPBody(params_data)
    
    OSX::NSURLConnection.alloc.initWithRequest_delegate(request, self)
  end
  
  def connectionDidFinishLoading(connection)
    close
  end
  
  def connection_didFailWithError(connection, error)
    close
  end
end
