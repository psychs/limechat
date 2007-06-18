# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class User
  attr_accessor :nick, :username, :address, :o, :v
  
  def initialize(nick, *args)
    @nick = nick
    @username = args[0] || ''
    @address = args[1] || ''
    @o = args[2] || false
    @v = args[3] || false
  end
end
