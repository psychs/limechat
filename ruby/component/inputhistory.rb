# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class InputHistory
  
  MAX_SIZE = 50
  
  def initialize
    @buf = []
    @pos = 0
  end
  
  def add(s)
    @pos = @buf.size
    return if s.empty?
    return if @buf[-1] == s
    @buf << s
    @buf.shift if @buf.size > MAX_SIZE
    @pos = @buf.size
  end
  
  def up(s)
    if s && !s.empty?
      cur = @buf[@pos]
      if !cur || cur != s
        # if the text was modified, append the current text
        @buf << s
        if @buf.size > MAX_SIZE
          @buf.shift
          @pos -= 1
        end
      end
    end
    @pos -= 1
    if @pos < 0
      @pos = 0
      nil
    else
      @buf[@pos] || ''
    end
  end
  
  def down(s)
    if !s || s.empty?
      @pos = @buf.size
      return nil
    end
    cur = @buf[@pos]
    if !cur || cur != s
      add(s)
      ''
    else
      @pos += 1
      @buf[@pos] || ''
    end
  end
end
