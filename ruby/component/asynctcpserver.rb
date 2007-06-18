# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'socket'

class AsyncTcpServer < OSX::NSObject
  include OSX
  attr_accessor :delegate, :port
  attr_reader :clients
  
  LISTEN_BACKLOG = 64
  
  def initialize
    @port = 0
    @clients = []
  end
  
  def open
    close
    begin
      @sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    	@sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1);
      @sock.bind(Socket.sockaddr_in(@port, "0.0.0.0"))
      @sock.listen(LISTEN_BACKLOG)
      @accept_thread = Thread.new { accept_loop }
      true
    rescue
      close
      false
    end
  end
  
  def close
    return unless @sock
    Thread.exclusive {
      begin
        @accept_thread.kill if @accept_thread
      rescue
      end
      @accept_thread = nil
      @sock.close
      @sock = nil
    }
  end
  
  def close_client(client)
    Thread.exclusive {
      client.close
      @clients.delete(client)
    }
  end
  
  def close_all_clients
    Thread.exclusive {
      @clients.each {|c| c.close }
      @clients.clear
    }
  end


  def tcpClientConnected(s)
    fire_event(:connect, s)
  end

  def tcpClientDisconnected(s)
    fire_event(:disconnect, s)
  end

  def tcpClientReceived(s)
    fire_event(:recv, s)
  end

  def tcpClientSent(s)
    fire_event(:send, s)
  end

  def tcpClientErrorOccured(s)
    fire_event(:error, s)
  end
  
  
  private
  
  def accept_loop
    while true
      begin
        socket, addr = @sock.accept
        fire_accept_event(socket, addr)
      rescue
        return
      end
    end
  end
  
  def fire_accept_event(client, addr)
    addr = Socket.unpack_sockaddr_in(addr)
    c = AsyncTcpClient.alloc.init
    c.delegate = self
    c.port = addr[0]
    c.host = addr[1]
    Thread.exclusive { @clients << c }
    fire_event(:accept)
    c.init_with_socket(client)
  end
  
  def fire_event(kind, sender=self)
    case kind
    when :accept; perform_event('tcpServerAccepted:', sender)
    when :connect; perform_event('tcpServerClientConnected:', sender)
    when :disconnect; perform_event('tcpServerClientDisconnected:', sender)
    when :recv; perform_event('tcpServerClientReceived:', sender)
    when :send; perform_event('tcpServerClientSent:', sender)
    when :error; perform_event('tcpServerClientErrorOccured:', sender)
    end
  end
  
  def perform_event(sel, sender)
    @delegate.performSelectorOnMainThread_withObject_waitUntilDone(sel, sender, false)
  end
end
