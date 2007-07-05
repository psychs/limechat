# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TcpClient < OSX::NSObject
  include OSX
  attr_accessor :delegate, :host, :port
  attr_reader :send_queue_size
  
  def initialize
    @tag = 0
    @host = ''
    @port = 0
    @send_queue_size = 0
  end
  
  def init_with_existing_connection(socket)
    close if @sock
    @buf = ''
    @tag += 1
    @sock = socket
    @sock.setUserData(@tag)
    @sock.setDelegate(self)
    @active = @connecting = true
  end
  
  def open
    close if @sock
    @buf = ''
    @tag += 1
    @sock = AsyncSocket.alloc.initWithDelegate_userData(self, @tag)
    @sock.connectToHost_onPort_error?(@host, @port, nil)
    @active = @connecting = true
    @send_queue_size = 0
  end
  
  def close
    return unless @sock
    @tag += 1
    @sock.disconnect
    @sock = nil
    @active = @connecting = false
    @send_queue_size = 0
  end
  
  def read
    s = @buf
    @buf = ''
    s
  end
  
  def readline
    n = @buf.index(/\r?\n/)
    return nil unless n
    s = @buf[0...n]
    @buf[0...n] = ''
    @buf.sub!(/\A\r?\n/, '')
    s
  end
  
  def write(str)
    return unless connected?
    data = NSData.dataWithRubyString(str)
    @sock.writeData_withTimeout_tag(data, -1.0, 0)
    wait_read
    @send_queue_size += 1
  end
  
  def active?
    @active
  end
  
  def connecting?
    @connecting
  end
  
  def connected?
    return false unless @sock
    return false unless check_tag(@sock)
    @sock.isConnected != 0
  end
  
  
  objc_method :onSocket_didConnectToHost_port, 'v@:@@S'
  def onSocket_didConnectToHost_port(sock, host, port)
    return unless check_tag(sock)
    wait_read
    @connecting = false
    @delegate.tcpclient_on_connect(self) if @delegate
  end
  
  objc_method :onSocket_willDisconnectWithError, 'v@:@@'
  def onSocket_willDisconnectWithError(sock, err)
    return unless check_tag(sock)
    @delegate.tcpclient_on_error(self, err) if @delegate && err
  end
  
  objc_method :onSocketDidDisconnect, 'v@:@'
  def onSocketDidDisconnect(sock)
    return unless check_tag(sock)
    close
    @delegate.tcpclient_on_disconnect(self) if @delegate
  end
  
  objc_method :onSocket_didReadData_withTag, 'v@:@@l'
  def onSocket_didReadData_withTag(sock, data, tag)
    return unless check_tag(sock)
    @buf += data.bytes.bytestr(data.length)
    wait_read
    @delegate.tcpclient_on_read(self) if @delegate
  end
  
  objc_method :onSocket_didWriteDataWithTag, 'v@:@l'
  def onSocket_didWriteDataWithTag(sock, tag)
    return unless check_tag(sock)
    @send_queue_size -= 1
    @delegate.tcpclient_on_write(self) if @delegate
  end
  
  
  private
  
  def wait_read
    @sock.readDataWithTimeout_tag(-1.0, 0)
  end
  
  def check_tag(sock)
    @tag == sock.userData.to_i
  end
end
