# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

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
