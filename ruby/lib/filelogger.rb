# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'utility'

class FileLogger
  
  def initialize(unit, channel)
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
    begin
      @fname.dirname.mkpath unless @fname.dirname.exist?
      unless @fname.exist?
        NSFileManager.defaultManager.createFileAtPath_contents_attributes(@fname.to_s, NSData.data, nil)
      end
      @file = NSFileHandle.fileHandleForUpdatingAtPath(@fname.to_s)
      if @file
        @file.seekToEndOfFile
      end
    rescue
      ;
    end
  end
  
  def build_filename
    base = Pathname.new(preferences.general.transcript_folder).expand_path
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
    base + "#{c}/#{pre}#{date}_#{u}.txt"
  end
end
