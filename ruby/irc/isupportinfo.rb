# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ISupportInfo
  def initialize
    reset
  end
  
  def reset
    @features = {
      :chanmodes => 'beIR,k,l,imnpstaqr'.split(','),
      :channeltypes => '#&!+',
      :modes => 3,
      :nicklen => 9,
    }
  end
  
  def [](key)
    @features[key]
  end
  
  def nicklen
    @features[:nicklen]
  end
  
  def modes_count
    @features[:modes]
  end
  
  def update(s)
    s = s.sub(/ are supported by this server\Z/, '')
    s.split(' ').each {|i| parse_param(i)}
  end
  
  private
  
  def parse_param(s)
    if s =~ /\A([-_a-zA-Z0-9]+)=(.*)\z/
      key, value = $1.downcase.to_sym, $2
      case key
      when :chanmodes
        @features[key] = value.split(',', 4)
      else
        value = value.to_i if value =~ /\A\d+\z/
        @features[key] = value
      end
    elsif !s.empty? && !s.include?("\0")
      @features[s.downcase.to_sym] = true
    end
  end
end
