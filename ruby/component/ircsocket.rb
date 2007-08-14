# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'timer'

class IRCSocket
  attr_accessor :delegate, :host, :port
  
  PENALTY_THREASHOLD = 3
  
  def initialize
    @sock = TcpClient.alloc.init
    @sock.delegate = self
    @timer = Timer.alloc.init
    @timer.delegate = self;
    @sendq = []
    @penalty = 0
  end
  
  def open
    @sock.host = @host
    @sock.port = @port
    @sock.open
  end
  
  def close
    @timer.stop
    @sendq = []
    @sock.close
  end
  
  def active?
    @sock.active?
  end
  
  def connecting?
    @sock.connecting?
  end
  
  def connected?
    @sock.connected?
  end
  
  def send(m)
    @sendq << m
    try_to_send
  end
  
  def clear_send_queue
    @sendq = []
  end
  
  def ready_to_send?
    !@sending && @penalty == 0 && @sendq.empty?
  end
  
  def timer_onTimer(sender)
    @penalty -= 1 if @penalty > 0
    try_to_send
  end
  
  def tcpclient_on_connect(sender)
    @timer.start(1)
    @sendq = []
    @delegate.ircsocket_on_connect if @delegate
  end
  
  def tcpclient_on_disconnect(sender)
    @timer.stop
    @sendq = []
    @delegate.ircsocket_on_disconnect if @delegate
  end
  
  def tcpclient_on_error(sender, err)
    @timer.stop
    @sendq = []
    @delegate.ircsocket_on_error(err) if @delegate
  end
  
  def tcpclient_on_read(sender)
    loop do
      s = @sock.readline
      break unless s
      s = s.gsub("\x00", ' ')   # workaround for plum's bug
      m = IRCReceiveMessage.new(s)
      @delegate.ircsocket_on_receive(m) if @delegate
    end
  end
  
  def tcpclient_on_write(sender)
    @sending = false
    try_to_send
  end
  
  
  private
  
  def try_to_send
    return if @sending
    return if @penalty >= PENALTY_THREASHOLD
    return if @sendq.empty?
    @sending = true
    m = @sendq.shift
    m.build
    @penalty += m.penalty
    @sock.write(m.raw)
    @delegate.ircsocket_on_send(m) if @delegate
  end
end
