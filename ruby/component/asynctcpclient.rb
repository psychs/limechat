# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'thread'
require 'socket'
require 'resolv-replace'
require 'timeout'

class AsyncTcpClient < NSObject
  attr_accessor :delegate, :host, :port
  attr_reader :error, :sending
  
  CONNECT_TIMEOUT = 20
  
  def initialize
    @sendq = Queue.new
    @sending = false
    @recvbuf = ''
  end
  
  def open
    close
    @sendq.clear
    @sending = false
    @recvbuf = ''
    @connect_thread = Thread.new { do_connect }
  end
  
  def init_with_socket(socket)
    @sock = socket
    @connect_thread = Thread.new { start_loop }
  end
  
  def close
    return unless @sock
    Thread.exclusive {
      begin
        @send_thread.kill if @send_thread
      rescue
      end
      begin
        @connect_thread.kill if @connect_thread
      rescue
      end
      @send_thread = nil
      @connect_thread = nil
      @sock.close
      @sock = nil
      @sendq.clear
      @sending = false
      @recvbuf = ''
    }
  end
  
  def send_queue_size
    @sendq.size
  end
  
  def read
    s = nil
    Thread.exclusive {
      s = @recvbuf
      @recvbuf = ''
    }
    s
  end
  
  def write(s)
    @sendq.push(s)
  end
  
  
  private
  
  def do_connect
    begin
      timeout(CONNECT_TIMEOUT) { @sock = TCPSocket.open(@host, @port) }
    rescue TimeoutError
      @error = 'Connect timeout'
      fire_event(:error)
      close
      return
    rescue
      @error = $!.to_s
      fire_event(:error)
      close
      return
    end
    start_loop
  end
  
  def start_loop
    fire_event(:connect)
    @send_thread = Thread.new { send_loop }
    recv_loop
  end
  
  def recv_loop
    loop do
      begin
        s = @sock.recv(1024 * 64)
        if !s || s.empty?
          fire_event(:disconnect)
          close
          return
        end
        Thread.exclusive { @recvbuf << s }
        fire_event(:recv)
      rescue
        @error = $!.to_s
        fire_event(:error)
        close
        return
      end
    end
  end
  
  def send_loop
    loop do
      begin
        s = @sendq.pop
        @sending = true
        slen = s.size
        until s.empty?
          len = @sock.send(s, 0)
          s[0...len] = ''
        end
        @sending = false
        fire_event(:send)
      rescue
        @error = $!.to_s
        fire_event(:error)
        close
        return
      end
    end
  end
  
  def fire_event(kind)
    case kind
    when :connect; perform_event('tcpClientConnected:')
    when :disconnect; perform_event('tcpClientDisconnected:')
    when :recv; perform_event('tcpClientReceived:')
    when :send; perform_event('tcpClientSent:')
    when :error; perform_event('tcpClientErrorOccured:')
    end
  end
  
  def perform_event(sel)
    @delegate.performSelectorOnMainThread_withObject_waitUntilDone(sel, self, false)
  end
end
