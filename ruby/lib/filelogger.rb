# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'utility'

class AFileLogger
  
  def initialize(client, channel)
    @client = client
    @channel = channel
  end
  
  def close
    if @file
      @file.closeFile
      @file = nil
    end
  end
  
  def writeLine(s)
    open unless @file
    if @file
      @file.writeData(NSData.dataWithRubyString(s + "\n"))
    end
  end
  
  def reopenIfNeeded
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
    u = @client.name.safe_filename
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
