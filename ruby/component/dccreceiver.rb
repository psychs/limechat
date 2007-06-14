# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class DccReceiver
  attr_accessor :delegate, :uid, :sender_nick
  attr_accessor :host, :port, :path, :filename, :size, :version
  attr_reader :received_size, :status, :error, :download_filename
  attr_accessor :progress_bar
  
  # RS_WAIT, RS_ERROR, RS_STOP, RS_WAITSTART, RS_WAITCONNECT, 
  # RS_RESUME, RS_RECEIVE, RS_COMPLETE
  
  # waiting, error, stop, connecting
  # receiving, complete
  
  RECORDS_LEN = 10
  
  def initialize
    @size = 0
    @version = 0
    @received_size = 0
    @status = :waiting
    @records = []
    @rec = 0
  end
  
  def speed
    return 0 if @records.empty? || @status != :receiving
    @records.inject(0) {|v,i| v += i }.to_f / @records.length.to_f
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
    @delegate.dccreceiver_on_close(self) if @delegate
  end
  
  
  def tcpclient_on_connect(sender)
    @received_size = 0
    @status = :receiving
    open_file
    @delegate.dccreceiver_on_open(self) if @delegate
    @delegate.dccreceiver_on_change(self) if @delegate
  end
  
  def tcpclient_on_disconnect(sender)
    puts '*** disconnect'
    close
    @delegate.dccreceiver_on_change(self) if @delegate
  end
  
  def tcpclient_on_error(sender, err)
    puts '*** error'
    @status = :error
    @error = err.localizedDescription.to_s
    close_file
    @delegate.dccreceiver_on_close(self) if @delegate
    @delegate.dccreceiver_on_change(self) if @delegate
  end
  
  def tcpclient_on_read(sender)
    s = @sock.read
    @received_size += s.length
    @rec += s.length
    until s.empty? do
      n = @file.write(s)
      s[0...n] = '' if n > 0
    end
    @progress_bar.setDoubleValue(@received_size) if @progress_bar
    if @received_size >= @size
      puts '*** complete ' + @filename
      @status = :complete
      close
      @delegate.dccreceiver_on_change(self) if @delegate
    end
  end
  
  def tcpclient_on_write(sender)
  end
  
  def on_timer
    return if @status != :receiving
    @records << @rec
    @records.shift if @records.length > RECORDS_LEN
    @rec = 0
  end
  
  
  private
  
  PREFIX = '__download__'
  
  def open_file
    return if @file
    base = File.basename(@filename, '.*')
    ext = File.extname(@filename)
    @download_filename = @path + PREFIX + @filename
    i = 0
    while File.exist?(@download_filename)
      @download_filename = @path + PREFIX + base + "_#{i}" + ext
      i += 1
    end
    begin
      @file = File.open(@download_filename, 'w+b')
    rescue
      puts '*** file open error'
      p $!
    end
  end
  
  def close_file
    if @file
      @file.close
      @file = nil
      if @status == :complete
        base = File.basename(@filename, '.*')
        ext = File.extname(@filename)
        fname = @path + @filename
        i = 0
        while File.exist?(fname)
          fname = @path + base + "_#{i}" + ext
          i += 1
        end
        File.rename(@download_filename, fname)
      end
    end
  end
end
