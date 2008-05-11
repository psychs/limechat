# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class Plugin
  def self.on_load
    puts 'on_load'
  end
  
  def self.on_unload
    puts 'on_unload'
  end
end
