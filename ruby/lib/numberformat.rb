# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module NumberFormat
  
  def format_time(sec=self)
    min,sec  = sec.divmod(60)
    hour,min = min.divmod(60)
    hour >= 1 ? sprintf("%d:%02d:%02d", hour, min, sec) : sprintf("%d:%02d", min, sec)
  end
  
  Units = %w[bytes KB MB GB TB]
  
  def format_size(bytes=self)
    unit = (Math.log(bytes)/Math.log(1024)).floor
    unit = 4 if unit > 4
    data = bytes/(1024.0**unit)
    format = (unit == 0 || data >= 10) ? "%d %s" : "%1.1f %s"
    sprintf(format, data, Units[unit])
  end
  
  extend self
end
