# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'

class DccReceiver
  attr_accessor :delegate, :uid, :peer_nick, :host, :port, :size, :version
  attr_reader :processed_size, :status, :error, :icon, :download_filename
  attr_accessor :progress_bar
  
  # status: waiting, error, stop, connecting, receiving, complete
  
  RECORDS_LEN = 10
  
  def initialize
    @version = 0
    @size = 0
    @processed_size = 0
    @status = :waiting
    @records = []
    @rec = 0
  end
  
  def path=(v)
    @path = Pathname.new(v).expand_path
  end
  
  def filename=(v)
    @filename = Pathname.new(v)
    ext = @filename.extname
    ext[0] = '' if ext[0..0] == '.'
    @icon = NSWorkspace.sharedWorkspace.iconForFileType(ext)
  end
  
  def filename
    @filename.to_s
  end
  
  def speed
    return 0 if @records.empty? || @status != :receiving
    @records.inject(0) {|v,i| v + i }.to_f / @records.size.to_f
  end
  
  def open
    close if @sock
    @records = []
    @rec = 0
    @status = :connecting
    
    @sock = TcpClient.alloc.init
    @sock.delegate = self
    @sock.host = @host
    @sock.port = @port
    @sock.open
  end
  
  def close
    if @sock
      @sock.close
      @sock = nil
    end
    close_file
    @status = :stop if @status != :error && @status != :complete
    @delegate.dccreceiver_on_close(self)
  end
  
  
  def tcpclient_on_connect(sender)
    @processed_size = 0
    @status = :receiving
    open_file
    @delegate.dccreceiver_on_open(self)
  end
  
  def tcpclient_on_disconnect(sender)
    return if @status == :complete || @status == :error
    @status = :error
    @error = 'Disconnected'
    close
    @delegate.dccreceiver_on_error(self)
  end
  
  def tcpclient_on_error(sender, err)
    return if @status == :complete || @status == :error
    @status = :error
    @error = err.localizedDescription.to_s
    close
    @delegate.dccreceiver_on_error(self)
  end
  
  def tcpclient_on_read(sender)
    s = @sock.read
    @processed_size += s.size
    @rec += s.size
    until s.empty?
      n = @file.write(s)
      s[0...n] = '' if n > 0
    end
    if @version < 2
      rsize = @processed_size & 0xffffffff
      ack = sprintf("%c%c%c%c", (rsize >> 24) & 0xff, (rsize >> 16) & 0xff, (rsize >> 8) & 0xff, rsize & 0xff)
      @sock.write(ack)
    end
    
    @progress_bar.setDoubleValue(@processed_size)
    @progress_bar.setNeedsDisplay(true)
    if @processed_size >= @size
      @status = :complete
      close
      @delegate.dccreceiver_on_complete(self)
    end
  end
  
  def tcpclient_on_write(sender)
  end
  
  def on_timer
    return if @status != :receiving
    @records << @rec
    @records.shift if @records.size > RECORDS_LEN
    @rec = 0
  end
  
  
  private
  
  PREFIX = '__download__'
  
  def open_file
    return if @file
    base = @filename.basename('.*')
    ext = @filename.extname
    @download_filename = @path + (PREFIX + @filename.to_s)
    i = 0
    while @download_filename.exist?
      @download_filename = @path + (PREFIX + base.to_s + "_#{i}" + ext)
      i += 1
    end
    begin
      @download_filename.dirname.mkpath unless @download_filename.dirname.exist?
      @file = @download_filename.open('w+b')
    rescue
      @status = :error
      @error = 'Could not open file'
      close
    end
  end
  
  def close_file
    return unless @file
    @file.close
    @file = nil
    if @status == :complete
      base = @filename.basename('.*')
      ext = @filename.extname
      fname = @path + @filename
      i = 0
      while fname.exist?
        fname = @path + (base.to_s + "_#{i}" + ext)
        i += 1
      end
      @download_filename.rename(fname)
      @download_filename = fname
    end
  end
end
