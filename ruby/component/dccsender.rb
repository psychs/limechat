# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class DccSender
  
  def tcpserver_on_accept(sender, client)
    puts '*** accept'
  end
  
  def tcpserver_on_connect(sender, client)
    puts '*** connect'
  end
  
  def tcpserver_on_error(sender, client, err)
    puts '*** error'
  end
  
  def tcpserver_on_disconnect(sender, client)
    puts '*** disconnect'
  end
  
  def tcpserver_on_read(sender, client)
    puts '*** read'
    client.write(client.read)
  end
  
  def tcpserver_on_write(sender, client)
    puts '*** write'
  end
end
