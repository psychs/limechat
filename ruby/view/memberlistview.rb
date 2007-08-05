# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'listview'

class MemberListView < ListView
  include OSX
  attr_accessor :key_delegate
  
  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 123..126 # cursor keys
      when 116,121  # page up/down
      else
        @key_delegate.memberListView_keyDown(e)
        return
      end
    end
    super_keyDown(e)
  end
end
