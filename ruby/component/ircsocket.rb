# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'timer'

class IRCSocket
  
  PENALTY_THREASHOLD = 10
  
  attr_accessor :delegate, :host, :port, :ssl
  attr_accessor :useSystemSocks, :useSocks, :socks_version, :proxy_host, :proxy_port, :proxy_user, :proxy_password
  
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
    @sock.ssl = @ssl
    @sock.useSystemSocks = @useSystemSocks
    @sock.useSocks = @useSocks
    @sock.socks_version = @socks_version
    @sock.proxy_host = @proxy_host
    @sock.proxy_port = @proxy_port
    @sock.proxy_user = @proxy_user
    @sock.proxy_password = @proxy_password
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
    @penalty < PENALTY_THREASHOLD
  end
  
  def timer_onTimer(sender)
    @penalty -= 2 if @penalty > 0
    try_to_send
  end
  
  def tcpclient_on_connect(sender)
    @timer.start(2)
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
      @delegate.ircsocket_on_receive(s) if @delegate
    end
  end
  
  def tcpclient_on_write(sender)
    try_to_send
  end
  
  private
  
  def try_to_send
    while @penalty < PENALTY_THREASHOLD && !@sendq.empty?
      m = @sendq.shift
      m.build
      @penalty += m.penalty
      @sock.write(m.to_s)
      @delegate.ircsocket_on_send(m) if @delegate
    end
  end
end
