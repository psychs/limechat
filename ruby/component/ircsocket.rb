# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'timer'

class IRCSocket < NSObject
  
  attr_accessor :delegate, :host, :port, :ssl
  attr_accessor :useSystemSocks, :useSocks, :socks_version, :proxy_host, :proxy_port, :proxy_user, :proxy_password
  
  def initialize
    @sock = TCPClient.alloc.init
    @sock.delegate = self
    @timer = Timer.alloc.init
    @timer.delegate = self;
    @sendq = []
    @penalty = 0
    @sending = false
  end
  
  def open
    @sock.host = @host
    @sock.port = @port
    @sock.useSSL = @ssl
    @sock.useSystemSocks = @useSystemSocks
    @sock.useSocks = @useSocks
    @sock.socksVersion = @socks_version
    @sock.proxyHost = @proxy_host
    @sock.proxyPort = @proxy_port
    @sock.proxyUser = @proxy_user
    @sock.proxyPassword = @proxy_password
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
    !@sending && @penalty == 0
  end
  
  def timerOnTimer(sender)
    @penalty -= 2 if @penalty > 0
    @penalty = 0 if @penalty < 0
    try_to_send
  end
  
  def tcpClientDidConnect(sender)
    @timer.start(2)
    @sendq = []
    @delegate.ircConnectionDidConnect if @delegate
  end
  
  def tcpClientDidDisconnect(sender)
    @timer.stop
    @sendq = []
    @delegate.ircConnectionDidDisconnect if @delegate
  end
  
  def tcpClient_error(sender, err)
    @timer.stop
    @sendq = []
    @delegate.ircConnectionDidError(err) if @delegate
  end
  
  def tcpClientDidReceiveData(sender)
    loop do
      data = @sock.readLine
      break unless data
      s = data.rubyString
      s = s.gsub("\x00", ' ')   # workaround for plum's bug
      @delegate.ircConnectionDidReceive(s) if @delegate
    end
  end
  
  def tcpClientDidSendData(sender)
    @sending = false
    try_to_send
  end
  
  private
  
  PENALTY_THREASHOLD = 3
  
  def try_to_send
    return if @sendq.empty?
    return if @sending
    return if @penalty > PENALTY_THREASHOLD
    
    @sending = true
    m = @sendq.shift
    m.build
    @penalty += m.penalty
    @sock.write(NSData.dataWithRubyString(m.to_s))
    @delegate.ircConnectionWillSend(m) if @delegate
  end
end
