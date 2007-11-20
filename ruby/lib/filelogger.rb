require 'fileutils'

class FileLogger
  include OSX
  
  def initialize(pref, unit, channel)
    @pref = pref
    @unit = unit
    @channel = channel
  end
  
  def close
    if @file
      @file.closeFile
      @file = nil
    end
  end
  
  def write_line(s)
    open unless @file
    if @file
      @file.writeData(NSData.dataWithRubyString(s + "\n"))
    end
  end
  
  def reopen_if_needed
    open if @fname != build_filename
  end

  private
  
  def open
    close if @file
    @fname = build_filename
    FileUtils.mkpath(File.dirname(@fname))
    unless File.exist?(@fname)
      NSFileManager.defaultManager.createFileAtPath_contents_attributes(@fname, NSData.data, nil)
    end
    @file = NSFileHandle.fileHandleForUpdatingAtPath(@fname)
    if @file
      @file.seekToEndOfFile
    end
  end
  
  def build_filename
    base = File.expand_path(@pref.gen.transcript_folder)
    u = @unit.name.safe_filename
    date = Time.now.strftime('%Y-%m-%d')
    pre = ''
    if !@channel
      c = 'Console'
    elsif @channel.talk?
      c = 'Talk'
      pre = @channel.name.safe_filename + '_'
    else
      c = @channel.name.safe_filename
    end
    "#{base}/#{c}/#{pre}#{date}_#{u}.txt"
  end
end
