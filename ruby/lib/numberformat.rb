# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module NumberFormat
  class << self
    def format_time(sec)
      min = sec / 60
      sec %= 60
      hour = min / 60
      min %= 60
      if hour >= 1
        sprintf("%d:%02d:%02d", hour, min, sec)
      else
        sprintf("%d:%02d", min, sec)
      end
    end
    
    def format_size(bytes)
      kb = bytes / 1024.0
      mb = kb / 1024.0
      gb = mb / 1024.0
      if gb >= 1
        if gb >= 10
          sprintf("%d GB", gb)
        else
          sprintf("%1.1f GB", gb)
        end
      elsif mb >= 1
        if mb >= 10
          sprintf("%d MB", mb)
        else
          sprintf("%1.1f MB", mb)
        end
      else
        sprintf("%d KB", kb)
      end
    end
  end
end
