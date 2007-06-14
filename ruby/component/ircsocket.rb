# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class IRCSocket
  attr_accessor :delegate, :host, :port
  
  def initialize
    @sock = TcpClient.alloc.init
    @sock.delegate = self
  end
  
  def open
    @sock.host = @host
    @sock.port = @port
    @sock.open
  end
  
  def close
    @sock.close
  end
  
  def send(m)
    m.build
    @sock.write(m.raw)
    @delegate.ircsocket_on_send(m) if @delegate
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
  
  
  def tcpclient_on_connect(sender)
    @delegate.ircsocket_on_connect if @delegate
  end
  
  def tcpclient_on_disconnect(sender)
    @delegate.ircsocket_on_disconnect if @delegate
  end
  
  def tcpclient_on_error(sender, err)
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
  end
end
