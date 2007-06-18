# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class DccSender
  attr_accessor :delegate, :uid, :receiver_nick
  attr_accessor :port
  attr_reader :full_filename, :filename, :size, :sent_size, :status, :error
  attr_accessor :progress_bar
  
  RECORDS_LEN = 10
  
  def initialize
    @version = 0
    @size = @sent_size = 0
    @status = :waiting
    @records = []
    @rec = 0
  end
  
  def full_filename=(v)
    @full_filename = v
    @size = File.size(@full_filename)
    @filename = File.basename(@full_filename)
  end
  
  def speed
    return 0 if @records.empty? || @status != :sending
    @records.inject(0) {|v,i| v += i }.to_f / @records.length.to_f
  end
  
  def open
    close if @sock
    @records = []
    @rec = 0
    @status = :waiting
    
    @sock = TcpServer.alloc.init
    @sock.delegate = self
    @sock.port = @port
    res = @sock.open
    return false unless res
    @status = :listening
    open_file
    return false unless @file
    @sent_size = 0
    @delegate.dccsender_on_listen(self)
    true
  end
  
  def close
    if @sock
      @sock.close_all_clients
      @sock.close
      @sock = nil
      @c = nil
    end
    close_file
    @status = :stop if @status != :error && @status != :complete
    @delegate.dccsender_on_close(self)
  end
  
  
  def tcpserver_on_connect(sender, c)
    @sock.close if @sock
    @c = c
    @status = :sending
    @delegate.dccsender_on_connect(self)
    send
  end
  
  def tcpserver_on_error(sender, c, err)
    puts '*** error'
    puts err
  end
  
  def tcpserver_on_disconnect(sender, c)
    puts '*** disconnect'
  end
  
  def tcpserver_on_read(sender, c)
    c.read
  end
  
  def tcpserver_on_write(sender, c)
    if @status == :complete
      if c.send_queue_size == 0 && !c.sending
        close
      end
    else
      send
    end
  end
  
  def on_timer
    return if @status != :sending
    @records << @rec
    @records.shift if @records.length > RECORDS_LEN
    @rec = 0
    send
  end
  
  
  private
  
  BUFSIZE = 1024 * 64
  RATE_LIMIT = 1024 * 1024
  
  def send
    return if @status == :complete
    return unless @c
    loop do
      return if @rec >= RATE_LIMIT
      if @sent_size >= @size
        @status = :complete
        close_file
        return
      end
      s = @file.read(BUFSIZE)
      len = s.length
      @sent_size += len
      @rec += len
      @c.write(s)
      @progress_bar.setDoubleValue(@sent_size)
      @progress_bar.setNeedsDisplay(true)
    end
  end
  
  def open_file
    close_file if @file
    begin
      @file = File.open(@full_filename, 'rb')
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
  end
end
