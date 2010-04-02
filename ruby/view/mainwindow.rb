# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MainWindow < NSWindow
  def initialize
    @keyHandler = KeyEventHandler.new
  end
  
  def sendEvent(e)
    if e.oc_type == NSKeyDown
      return if @keyHandler.process_key_event(e)
    end
    super_sendEvent(e)
  end
  
  def register_keyHandler(*args, &handler)
    @keyHandler.register_keyHandler(*args, &handler)
  end
end
