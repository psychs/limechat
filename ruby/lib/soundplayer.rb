# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module SoundPlayer
  
  def play(name)
    return if name == nil || name.empty?
    if name == 'Beep'
      OSX.NSBeep
    else
      s = OSX::NSSound.soundNamed(name)
      s.play if s
    end
  end
  
  extend self
end
