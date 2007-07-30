# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module LogRenderer
  class << self
    
    def render_body(body, keywords, dislike_words)
      effects, body = process_effects(body)
      urls = process_urls(body)
      addrs = process_addresses(body)
      addrs.delete_if {|a| urls.find {|u| intersect?(a,u)}} unless urls.empty?
      keywords = process_keywords(body, urls, keywords, dislike_words)
      addrs.delete_if {|a| keywords.find {|k| intersect?(a,k)}} unless keywords.empty?
      events = combine_events(effects, urls, addrs, keywords)
      
      if events.empty?
        body = escape_str(body)
        return [body, false]
      end

      effect = nil
      url = nil
      addr = nil
      key = nil
      pending_effect = nil
    
      s = ''
      pos = 0
      body.each_char do |c|
        evs = events.select {|i| i[:pos] == pos}
        unless evs.empty?
          t = ''
          evs.each do |e|
            case e[:kind]
            when :effect
              if url || key
                pending_effect = e[:off] ? nil : e
              else
                if e[:off]
                  effect = nil
                  t += render_end_tag(:effect)
                else
                  t += render_end_tag(:effect) if effect
                  effect = e
                  t += render_start_tag(e)
                end
              end
            when :urlend
              if url
                url = nil
                t += render_end_tag(:url)
              end
              if !effect && pending_effect
                effect = pending_effect
                pending_effect = nil
                t += render_start_tag(effect)
              end
            when :addrend
              if addr
                addr = nil
                t += render_end_tag(:address)
              end
              if !effect && pending_effect
                effect = pending_effect
                pending_effect = nil
                t += render_start_tag(effect)
              end
            when :keyend
              if key
                key = nil
                t += render_end_tag(:key)
              end
              if !effect && pending_effect
                effect = pending_effect
                pending_effect = nil
                t += render_start_tag(effect)
              end
            when :urlstart
              if effect
                pending_effect = effect
                effect = nil
                t += render_end_tag(:effect)
              end
              t += render_end_tag(:url) if url
              url = e
              t += render_start_tag(e)
            when :addrstart
              if effect
                pending_effect = effect
                effect = nil
                t += render_end_tag(:effect)
              end
              t += render_end_tag(:address) if addr
              addr = e
              t += render_start_tag(e)
            when :keystart
              if effect
                pending_effect = effect
                effect = nil
                t += render_end_tag(:effect)
              end
              t += render_end_tag(:key) if key
              key = e
              t += render_start_tag(e)
            end
          end
          s += t
        end
        
        pos += c.length
        s += escape_char(c)
      end
    
      s += render_end_tag(:url) if url
      s += render_end_tag(:key) if key
      s += render_end_tag(:effect) if effect
      [s, !keywords.empty?]
    end
    
    
    private
    
    def escape_str(s)
      a = ''
      s.each_char {|c| a += escape_char(c)}
      a
    end
    
    def escape_char(c)
      case c
      when '<'; '&lt;'
      when '>'; '&gt;'
      when '&'; '&amp;'
      when '"'; '&quot;'
      when ' '; '&nbsp;'
      when "\t"; '&nbsp;&nbsp;&nbsp;&nbsp;'
      else c
      end
    end
    
    def num_to_color(n)
      case n%16
      when 0; '#fff'
      when 1; '#000'
      when 2; '#008'
      when 3; '#080'
      when 4; '#f00'
      when 5; '#800'
      when 6; '#808'
      when 7; '#f80'
      when 8; '#ff0'
      when 9; '#0f0'
      when 10; '#088'
      when 11; '#0ff'
      when 12; '#00f'
      when 13; '#f0f'
      when 14; '#888'
      when 15; '#ccc'
      end
    end
    
    def render_start_tag(e)
      case e[:kind]
      when :urlstart; %Q[<a class="url" href="#{e[:url]}" oncontextmenu="on_url_contextmenu()">]
      when :addrstart; '<span class="address" oncontextmenu="on_address_contextmenu()">'
      when :keystart; '<strong class="highlight">'
      when :effect
        s = '<span class="effect" style="'
        s += 'font-weight:bold;' if e[:bold]
        s += 'text-decoration:underline;' if e[:underline]
        s += 'font-style:italic;' if e[:reverse]
      
        text = e[:text]
        if text
          text = num_to_color(text)
          s += "color:#{text};"
        end
      
        back = e[:back]
        if back
          back = num_to_color(back)
          s += "background-color:#{back};"
        end
      
        s += '">'
        s
      end
    end
  
    def render_end_tag(kind)
      case kind
      when :url; '</a>'
      when :address; '</span>'
      when :key; '</strong>'
      when :effect; '</span>'
      end
    end

    def process_effects(body)
      effects = []
      s = body.dup
      b = ''
      offset = 0
      n = 0
      while /[\x02\x0f\x16\x1f]|\x03((\d{1,2})(,(\d{1,2}))?)?/ =~ s
        left = $~.begin(0)
        right = $~.end(0)
        t = s[left...right]
        pos = offset + left
        case t[0]
        when 0x02; effects << { :type => :bold, :pos => pos }
        when 0x0f; effects << { :type => :stop, :pos => pos }
        when 0x1f; effects << { :type => :underline, :pos => pos }
        when 0x16; effects << { :type => :reverse, :pos => pos }
        when 0x03
          text = $1
          text = text.to_i if text
          back = $4
          back = back.to_i if back
          effects << { :type => :color, :pos => pos, :serial => n, :text => text, :back => back }
        end
        b += s[0...left]
        s[0...right] = ''
        offset += left
        n += 1
      end
      body = b + s
      return [[], body] if effects.empty?
    
      bold = underline = reverse = false
      text = back = nil
    
      hash = {}
      effects.each do |i|
        case i[:type]
        when :bold; bold = !bold
        when :underline; underline = !underline
        when :reverse; reverse = !reverse
        when :stop
          next if !bold && !underline && !reverse && !text && !back
          bold = underline = reverse = false
          text = back = nil 
        when :color
          next if text == i[:text] && back == i[:back]
          text = i[:text]
          back = i[:back]
        end
        off = !bold && !underline && !reverse && !text && !back
        hash[i[:pos]] = { :pos => i[:pos], :serial => i[:serial], :bold => bold, :underline => underline, :reverse => reverse, :text => text, :back => back, :off => off }
      end
      effects = hash.keys.sort.map {|k| hash[k]}
    
      [effects, body]
    end
  
    def process_urls(body)
      unless @urlrex
        @urlrex = /(?:h?ttps?|ftp):\/\/[-_a-zA-Z0-9.!~*':@%]+(?:(?:\/[-_a-zA-Z0-9.!~*'%;\/?:@&=+$,#]*[-_a-zA-Z0-9\/?])|\/|)/i
      end
      urls = []
      s = body.dup
      offset = 0
      while @urlrex =~ s
        left = $~.begin(0)
        right = $~.end(0)
        url = s[left...right]
        urls << { :url => url, :pos => offset+left, :len => right-left }
        s[0...right] = ''
        offset += right
      end
      urls
    end

    def process_addresses(body)
      unless @addrex
    	  @addrex = /(([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+(com|net|org|edu|gov|mi|int|biz|pro|info|coop|name|aero|museum|ac|ad|ae|af|ag|ai|a|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|c|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|fi|fj|fk|fm|fo|fr|fx|ga|gb|gd|ge|gf|gg|gh|gi|g|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|i|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|m|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|ne|nf|ng|ni|n|no|np|nr|nt|nu|nz|om|pa|pe|pf|pg|ph|pk|p|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|s|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|wf|wg|ws|ye|yt|yu|za|zm|zr|zw))|(((\d{1,3}\.){3}[\d]{1,3}))/i
  	  end
      addrs = []
      s = body.dup
      offset = 0
      while @addrex =~ s
        left = $~.begin(0)
        right = $~.end(0)
        addr = s[left...right]
        addrs << { :address => addr, :pos => offset+left, :len => right-left }
        s[0...right] = ''
        offset += right
      end
      addrs
    end
  
    def intersect?(a, b)
      al = a[:pos]
      ar = al + a[:len]
      bl = b[:pos]
      br = bl + b[:len]
      al <= bl && bl < ar || al < br && br <= ar || bl <= al && al < br || bl < ar && ar <= br
    end
  
    def process_keywords(body, urls, words, dislike_words)
      return [] unless words && !words.empty?
      
      keywords = []
      words.each do |w|
        s = body.dup
        offset = 0
        rex = Regexp.new(Regexp.escape(w), true)
        while rex =~ s
          left = $~.begin(0)
          right = $~.end(0)
          keywords << { :pos => offset+left, :len => right-left }
          s[0...right] = ''
          offset += right
        end
      end
      
      return [] if keywords.empty?
      keywords.sort! {|a,b| a[:pos] <=> b[:pos] }
      
      # eliminate keywords intersect one of urls
      keywords.delete_if {|k| urls.find {|u| intersect?(k,u)}} unless urls.empty?
      
      if dislike_words && !dislike_words.empty?
        dislike_matches = []
        dislike_words.each do |w|
          s = body.dup
          offset = 0
          rex = Regexp.new(Regexp.escape(w), true)
          while rex =~ s
            left = $~.begin(0)
            right = $~.end(0)
            dislike_matches << { :pos => offset+left, :len => right-left }
            s[0...right] = ''
            offset += right
          end
        end
        # eliminate keywords intersect one of dislike_words
        keywords.delete_if {|k| dislike_matches.find {|u| intersect?(k,u)}} unless dislike_matches.empty?
      end
    
      # combine keyword ranges
    
      new_keywords = []
      i = 0
      while i < keywords.length
        k = keywords[i]
        while true
          n = keywords[i+1]
          unless n
            new_keywords << k
            break
          end
          if k[:pos] + k[:len] >= n[:pos]
            k[:len] += n[:len] - (k[:pos] + k[:len] - n[:pos])
            i += 1
          else
            new_keywords << k
            break
          end
        end
        i += 1
      end
      new_keywords
    end
  
    def combine_events(effects, urls, addrs, keywords)
      events = []
      events += effects.map {|i| i[:kind] = :effect; i }
      urls.each do |i|
        s = i.dup
        s[:kind] = :urlstart
        events << s
        s = i.dup
        s[:kind] = :urlend
        s[:pos] += s[:len]
        events << s
      end
    
      addrs.each do |i|
        s = i.dup
        s[:kind] = :addrstart
        events << s
        s = i.dup
        s[:kind] = :addrend
        s[:pos] += s[:len]
        events << s
      end
    
      keywords.each do |i|
        s = i.dup
        s[:kind] = :keystart
        events << s
        s = i.dup
        s[:kind] = :keyend
        s[:pos] += s[:len]
        events << s
      end
      
      # sort:
      #   effect off < urlend == keyend == addrend < urlstart == keystart == addrstart < effect on
      #
      events.sort! do |a,b|
        cond = a[:pos] <=> b[:pos]
        if cond == 0
          if a[:kind] == b[:kind]
            if a[:kind] == :effect
              a[:serial] <=> b[:serial]
            else
              0
            end
          else
            x = a[:kind]
            y = b[:kind]
            if x == :effect && a[:off]
              -1
            elsif x == :effect && !a[:off]
              1
            elsif y == :effect && b[:off]
              1
            elsif y == :effect && !b[:off]
              -1
            elsif x == :urlend || x == :keyend || x == :addrend
              -1
            else
              1
            end
          end
        else
          cond
        end
      end
      
      events
    end
  end
end
