# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MainWindow < NSWindow
  def initialize
    @key_handler = KeyEventHandler.new
  end
  
  def sendEvent(e)
    if e.oc_type == NSKeyDown
      return if @key_handler.process_key_event(e)
    end
    super_sendEvent(e)
  end
  
  def register_key_handler(*args, &handler)
    @key_handler.register_key_handler(*args, &handler)
  end
end
