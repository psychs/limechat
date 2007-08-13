# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class DccSender
  attr_accessor :delegate, :pref, :uid, :peer_nick
  attr_reader :port, :full_filename, :filename, :size, :processed_size, :status, :error
  attr_accessor :progress_bar, :icon
  
	# SS_WAIT, SS_ERROR, SS_STOP, SS_WAITSTART, SS_WAITLISTEN,
	# SS_READY, SS_SEND, SS_COMPLETE
	
	# waiting, error, stop
	# listening, sending, complete

  RECORDS_LEN = 10
  
  def initialize
    @version = 0
    @size = @processed_size = 0
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
    @port = @pref.dcc.first_port
    unless do_open
      @port += 1
      if @pref.dcc.last_port < @port
        @status = :error
        @error = 'No available ports'
        @delegate.dccsender_on_error(self)
        return false
      end
    end
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
  
  def set_address_error
    @status = :error
    @error = 'Cannot detect your IP address'
    @delegate.dccsender_on_error(self)
  end
  
  
  def tcpserver_on_accept(sender, c)
  end
  
  def tcpserver_on_connect(sender, c)
    @sock.close if @sock
    @c = c
    @status = :sending
    @delegate.dccsender_on_connect(self)
    send
  end
  
  def tcpserver_on_error(sender, c, err)
    return if @status == :complete || @status == :error
    @status = :error
    @error = err
    close
    @delegate.dccsender_on_error(self)
  end
  
  def tcpserver_on_disconnect(sender, c)
    if @processed_size >= @size
      @status = :complete
      close
      return
    end
    return if @status == :complete || @status == :error
    @status = :error
    @error = 'Disconnected'
    close
    @delegate.dccsender_on_error(self)
  end
  
  def tcpserver_on_read(sender, c)
    c.read
  end
  
  def tcpserver_on_write(sender, c)
    if @processed_size >= @size
      if c.send_queue_size == 0
        @status = :complete
        @delegate.dccsender_on_complete(self)
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

  MAX_QUEUE_SIZE = 2
  BUFSIZE = 1024 * 64
  RATE_LIMIT = 1024 * 1024 * 5

  def send
    return if @status == :complete
    return if @processed_size >= @size
    return unless @c
    loop do
      return if @rec >= RATE_LIMIT
      return if @c.send_queue_size >= MAX_QUEUE_SIZE
      if @processed_size >= @size
        close_file
        return
      end
      s = @file.read(BUFSIZE)
      len = s.length
      @processed_size += len
      @rec += len
      @c.write(s)
      @progress_bar.setDoubleValue(@processed_size)
      @progress_bar.setNeedsDisplay(true)
    end
  end
  
  def do_open
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
    @processed_size = 0
    @delegate.dccsender_on_listen(self)
    true
  end
  
  def open_file
    close_file if @file
    begin
      @file = File.open(@full_filename, 'rb')
    rescue
      @status = :error
      @error = 'Could not open file'
      close
      @delegate.dccsender_on_error(self)
    end
  end
  
  def close_file
    return unless @file
    @file.close
    @file = nil
  end
end
