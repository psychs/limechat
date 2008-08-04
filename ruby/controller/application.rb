# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class LimeChatApplication < NSApplication
  def sendEvent(e)
    if e.oc_type == 14 && e.subtype == 6
      if delegate && delegate.respondsToSelector('applicationDidReceivedHotKey:')
        delegate.applicationDidReceivedHotKey(self)
      end
    end
    super_sendEvent(e)
  end
  
  def register_hot_key(keys, *mods)
    @hotkey ||= HotKeyManager.alloc.init
    key = KeyEventHandler.keynames_to_keycodes(keys)[0]
    m = KeyEventHandler.mods_to_modifier(mods)
    @hotkey.registerHotKeyCode_withModifier(key, m)
  end
  
  def unregister_hot_key
    @hotkey.unregisterHotKey if @hotkey
  end
end
