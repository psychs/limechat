# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TcpServer < NSObject
  attr_accessor :delegate, :port
  attr_reader :clients
  
  def initialize
    @port = 0
    @clients = []
  end
  
  def open
    close if @sock
    @buf = ''
    @sock = AsyncSocket.alloc.initWithDelegate(self)
    @active = @sock.acceptOnPort_error(@port, nil) != 0
    @sock = nil unless @active
    @active
  end
  
  def close
    return unless @sock
    @sock.disconnect
    @sock.release
    @sock = nil
    @active = false
  end
  
  def active?
    @active
  end
  
  def close_client(client)
    client.close
    @clients.delete(client)
  end
  
  def close_all_clients
    @clients.each {|c| c.close }
    @clients.clear
  end
  
  def onSocket_didAcceptNewSocket(sock, conn)
    c = TcpClient.alloc.init
    c.init_with_existing_connection(conn)
    c.delegate = self
    @clients << c
    @delegate.tcpserver_on_accept(self, c) if @delegate
  end
  
  
  def tcpClientDidConnect(sender)
    @delegate.tcpserver_on_connect(self, sender) if @delegate
  end
  
  def tcpClientDidDisconnect(sender)
    @delegate.tcpserver_on_disconnect(self, sender) if @delegate
    close_client(sender)
  end
  
  def tcpClient_error(sender, err)
    @delegate.tcpserver_on_error(self, sender, err) if @delegate
  end
  
  def tcpClientDidReceiveData(sender)
    @delegate.tcpserver_on_read(self, sender) if @delegate
  end
  
  def tcpClientDidSendData(sender)
    @delegate.tcpserver_on_write(self, sender) if @delegate
  end
end
