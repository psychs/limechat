# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module SoundPlayer
  include OSX
  
  def self.play(name)
    if name == 'Beep'
      OSX.NSBeep
    else
      s = NSSound.soundNamed(name)
      s.play if s
    end
  end
end
