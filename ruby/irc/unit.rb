# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'
require 'pathname'

class IRCUnit < NSObject
  attr_accessor :world, :log, :uid
  attr_reader :config, :channels, :mynick, :mymode, :encoding, :myaddress, :isupport, :reconnect
  attr_accessor :property_dialog
  attr_accessor :keyword, :unread
  attr_accessor :last_selected_channel, :last_input_text
  
  RECONNECT_TIME = 20
  RETRY_TIME = 240
  PONG_TIME = 130
  QUIT_TIME = 5
  WHO_TIME = 10
  
  def initialize
    @channels = []
    @whois_dialogs = []
    @connected = @login = @quitting = false
    @mynick = @inputnick = @sentnick = ''
    @trying_nick = -1
    @mymode = UserMode.new
    @myaddress = nil
    @join_address = nil
    @encoding = NSISO2022JPStringEncoding
    @isupport = ISupportInfo.new
    @in_whois = false
    @identify_msg = false
    @identify_ctcp = false
    @who_queue = []
    @who_wait = 0
    @timer_queue = []
    @resolver = HostResolver.alloc.initWithDelegate(self)
    reset_state
  end
  
  def reset_state
    @keyword = @unread = false
  end
  
  def newtalk
    false
  end
  
  def setup(seed)
    @config = seed.dup
    @config.channels = nil
    migrate
    
    @address_detection_method = preferences.dcc.address_detection_method
    if @address_detection_method == Preferences::Dcc::ADDR_DETECT_SPECIFY
      @resolver.resolve(preferences.dcc.myaddress)
    end
  end
  
  def migrate
    # migrate irc.friend.td.nu to irc.friend-chat.jp
    if @config.host =~ /^irc.friend.td.nu/
      @config.host = 'irc.friend-chat.jp'
    end
    
    # migrate wide servers
    case @config.host
    when /^irc.kyoto.wide.ad.jp/,/^irc.nara.wide.ad.jp/,/^irc.tokyo.wide.ad.jp/,/^irc.fujisawa.wide.ad.jp/,/^irc.huie.hokudai.ac.jp/,/^irc.media.kyoto-u.ac.jp/
      @config.host = 'irc.ircnet.ne.jp'
    end
  end
  
  def update_config(seed)
    @config = seed.dup
    chans = @config.channels
    @config.channels = nil
    
    ary = []
    chans.each do |i|
      c = find_channel(i.name)
      if c
        c.update_config(i)
        ary << c
        @channels.delete(c)
      else
        c = @world.create_channel(self, i, false, false)
        ary << c
      end
    end
    
    chs, nochs = @channels.partition {|i| i.channel? }
    ary += nochs
    chs.each {|i| part_channel(i) }
    
    @channels = ary
    @world.reload_tree
    @world.adjust_selection
  end
  
  def update_order(conf)
    chans = conf.channels
    ary = []
    chans.each do |i|
      c = find_channel(i.name)
      if c
        ary << c
        @channels.delete(c)
      end
    end
    chs, nochs = @channels.partition {|i| i.channel? }
    @channels = ary + chs + nochs
  end
  
  def update_autoop(conf)
    @config.autoop = conf.autoop
    conf.channels.each do |i|
      c = find_channel(i.name)
      c.update_autoop(i) if c
    end
  end
  
  def store_config
    u = @config.dup
    u.uid = @uid
    u.channels = []
    @channels.each do |c|
      u.channels << c.config.dup if c.channel?
    end
    u
  end
  
  def terminate
    quit
    close_dialogs
    @channels.each {|c| c.terminate }
    disconnect
  end
  
  def name
    @config.name
  end
  
  def name=(value)
    @config.name = value
  end
  
  def unit
    self
  end
  
  def unit?
    true
  end
  
  def connecting?
    @connecting
  end
  
  def connected?
    @connected && @conn != nil
  end
  
  def login?
    @login
  end
  
  def reconnecting?
    !connected? && !connecting? && @reconnect
  end
  
  def ready_to_send?
    login? && @conn.ready_to_send?
  end
  
  def eq(x, y)
    to_common_encoding(x).downcase == to_common_encoding(y).downcase
  end
  
  def to_dic
    h = @config.to_dic
    chs = @channels.select {|i| i.channel? }
    unless chs.empty?
      h[:channels] = chs.map {|i| i.to_dic }
    end
    h
  end
  
  def close_dialogs
    if @property_dialog
      @property_dialog.close
      @property_dialog = nil
    end
    @whois_dialogs.each {|d| d.close }
    @whois_dialogs.clear
    if @list_dialog
      @list_dialog.close
      @list_dialog = nil
    end
  end
  
  def auto_connect(delay)
    if delay == 0
      connect
    else
      @connect_delay = delay
    end
  end
  
  def connect(mode=:normal)
    @conn.close if @conn
    
    case mode
    when :normal; print_system_both(self, 'Connecting...')
    when :reconnect; print_system_both(self, 'Reconnecting...')
    when :retry; print_system_both(self, 'Retrying...')
    end
    
    @reconnect = true
    @reconnect_timer = RECONNECT_TIME
    @retry = true
    @retry_timer = RETRY_TIME
    
    @connecting = true
    @conn = IRCSocket.new
    @conn.delegate = self
    host = @config.host
    host = host.split(' ')[0] if host
    @conn.host = host
    @conn.port = @config.port.to_i
    @conn.ssl = @config.ssl
    
    case @config.proxy
    when IRCUnitConfig::PROXY_SOCKS_SYSTEM
      @conn.useSystemSocks = true
    when IRCUnitConfig::PROXY_SOCKS5,IRCUnitConfig::PROXY_SOCKS4
      @conn.useSocks = true
      @conn.socks_version = @config.proxy == IRCUnitConfig::PROXY_SOCKS4 ? 4 : 5
      @conn.proxy_host = @config.proxy_host
      @conn.proxy_port = @config.proxy_port
      @conn.proxy_user = @config.proxy_user
      @conn.proxy_password = @config.proxy_password
    end
    @conn.open
  end
  
  def disconnect(sleeping=false)
    @quitting = false
    @reconnect = false unless sleeping
    @conn.close if @conn
    change_state_to_off
  end
  
  def quit(comment=nil)
    return disconnect unless login?
    @quitting = true
    @quit_timer = QUIT_TIME
    @reconnect = false
    @conn.clear_send_queue
    comment = @config.leaving_comment unless comment
    send(:quit, comment)
  end
  
  def cancel_reconnect
    return if connected?
    return unless @reconnect
    @reconnect = false
    print_system(self, 'Stopped reconnecting')
  end
  
  def join_channel(channel, pass=nil, force=false)
    return unless login?
    unless force
      return if channel.active?
    end
    pass = channel.config.password if !pass || pass.empty?
    pass = nil if pass.empty?
    send(:join, channel.name, pass)
  end
  
  def part_channel(channel, comment=nil)
    return unless login?
    return unless channel.active?
    comment = @config.leaving_comment if !comment && @config.leaving_comment
    send(:part, channel.name, comment)
  end
  
  def kick(chname, nick, comment=nil)
    if comment
      send(:kick, chname, nick)
    else
      send(:kick, chname, nick, comment)
    end
  end
  
  def ban(chname, nick, user, address)
    send(:mode, chname, "+b #{nick}!#{user}@#{address}")
  end
  
  def change_op(channel, members, mode, plus)
    return unless login? && channel && channel.active? && channel.channel? && channel.op?
    members = members.map {|n| String === n ? channel.find_member(n) : n }
    members = members.compact
    members = members.select {|m| m.__send__(mode) != plus }
    members = members.map {|m| m.nick }
    max = @isupport.modes_count
    until members.empty?
      t = members[0...max]
      send(:mode, channel.name, (plus ? '+' : '-') + mode.to_s * t.size + ' ' + t.join(' '))
      members[0...max] = nil
    end
  end
  
  def check_all_autoop(channel)
    return unless login? && channel && channel.active? && channel.channel? && channel.op?
    channel.check_all_autoop
  end
  
  def check_autoop(channel, nick, mask)
    return unless login? && channel && channel.active? && channel.channel? && channel.op?
    channel.check_autoop(nick, mask)
  end
  
  def input_text(str, cmd)
    return false unless connected?
    sel = @world.selected
    str.split(/\r\n|\r|\n/).each do |s|
      next if s.empty?
      if s[0] == ?/ && s[1] != ?/
        s[0] = ''
        send_command(s)
      elsif sel == self
        send_command(s)
      else
        s[0] = '' if s[0] == ?/
        send_text(sel, cmd, s)
      end
    end
    true
  end
  
  def truncate_text(str, cmd, chname)
    max = IRC::BODY_LEN
    max -= to_common_encoding(chname).size
    max -= @mynick && !@mynick.empty? ? @mynick.size : @isupport.nicklen
    max -= @config.username.size
    max -= @join_address ? @join_address.size : IRC::ADDRESS_LEN
    case cmd
    when :notice; max -= 18
    when :action; max -= 28
    else          max -= 19
    end
    
    s = str.dup
    common = to_common_encoding(s)
    
    while common.size > max
      break unless s =~ /.\z/
      s = $~.pre_match
      common = to_common_encoding(s)
    end
    
    str[0...s.size] = ''
    s
  end
  
  def send_text(chan, cmd, str)
    return false unless login? && chan && cmd && str && !str.include?("\0")
    str.split(/\r\n|\r|\n/).each do |line|
      next if line.empty?
      s = to_local_encoding(to_common_encoding(line))
      
      loop do
        break if s.empty?
        t = truncate_text(s, cmd, chan.name)
        break if t.empty?
        print_both(chan, cmd, @mynick, t)
        command = cmd
        if command == :action
          command = :privmsg
          t = "\x01ACTION #{t}\x01"
        end
        send(command, chan.name, t)
      end
      
      # only watch private messages
      if cmd == :privmsg
        if line =~ /\A([^\s:]+):\s/ || line =~ /\A@([^\s:]+)\s/ || line =~ /[>＞]\s?([^\s]+)\z/
          recipient = chan.find_member($1)
          recipient.incoming_conversation! if recipient
        end
      end
    end
    true
  end
  
  def send_command(s, complete_target=true, target=nil)
    return false unless connected? && s && !s.include?("\0")
    s = expand_variables(s)
    command = s.token!
    return false if command.empty?
    cmd = command.downcase.to_sym
    target = nil
    
    if complete_target && target
      sel = target
    elsif complete_target && @world.selunit == self && @world.selchannel
      sel = @world.selchannel
    else
      sel = nil
    end
    
    opmsg = false
    
    # parse pseudo commands and alias
    case cmd
    when :ruby
      c = @world.selchannel || self
      if s.empty?
        print_both(c, :error_reply, "Input ruby expressions to execute")
      else
        begin
          result = eval(s).inspect
        rescue SyntaxError => e
          
        rescue Exception => e
          send_text(c, :privmsg, ">> #{s}")
          send_text(c, :privmsg, "=> #{result}")
        end
      end
      return true
		when :clear
			u, c = @world.sel
			if c
				c.log.clear
			elsif u
				u.log.clear
			end
			return true
    when :weights
      sel = @world.selchannel
      if sel
        print_both(self, :reply, "WEIGHTS: ") 
        sel.members.each do |m|
          if m.weight > 0
            out = "#{m.nick} - sent: #{m.incoming_weight} received: #{m.outgoing_weight} total: #{m.weight}" 
            print_both(self, :reply, out) 
          end
        end
      end
      return true
    when :query
      target = s.token!
      if target.empty?
        # close the current talk
        c = @world.selchannel
        if c && c.talk?
          @world.destroy_channel(c)
        end
      else
        # open a new talk
        c = find_channel(target)
        unless c
          @world.clear_text
          c = @world.create_talk(self, target)
        end
        @world.select(c)
      end
      return true
    when :close
      target = s.token!
      if target.empty?
        c = @world.selchannel
      else
        c = find_channel(target)
      end
      if c && c.talk?
        @world.destroy_channel(c)
      end
      return true
    when :timer
      interval = s.token!
      if interval =~ /^\d+$/
        @timer_queue << [interval.to_i, sel, s]
      else
        print_both(self, :error_reply, "timer command needs interval as a number") 
      end
      return true
    when :rejoin,:hop,:cycle
      c = @world.selchannel
      if c
        pass = c.mode.k
        pass = nil if pass.empty?
        part_channel(c)
        join_channel(c, pass, true)
      end
      return true
    when :omsg
      opmsg = true
      cmd = :privmsg
    when :onotice
      opmsg = true
      cmd = :notice
    when :msg,:m
      cmd = :privmsg
    when :leave
      cmd = :part
    when :j
      cmd = :join
    when :t
      cmd = :topic
    when :raw,:quote
      send_raw(s.token!, s)
      return true
    end
    
    # get target if needed
    case cmd
    when :privmsg,:notice,:action
      if opmsg
        if sel && sel.channel? && !s.channelname?
          target = sel.name
        else
          target = s.token!
        end
      else
        target = s.token!
      end
    when :me
      cmd = :action
      if sel
        target = sel.name
      else
        target = s.token!
      end
    when :part
      if sel && sel.channel? && !s.channelname?
        target = sel.name
      elsif sel && sel.talk? && !s.channelname?
        @world.destroy_channel(sel)
      else
        target = s.token!
      end
    when :topic
      if sel && sel.channel? && !s.channelname?
        target = sel.name
      else
        target = s.token!
      end
    when :mode,:kick
      if sel && sel.channel? && !s.modechannelname?
        target = sel.name
      else
        target = s.token!
      end
    when :join
      if sel && sel.channel? && !sel.active? && s.empty?
        target = sel.name
      else
        target = s.token!
        target = '#' + target unless target.channelname?
      end
    when :invite
      target = s.token!
    when :op,:deop,:halfop,:dehalfop,:voice,:devoice,:ban,:unban
      if sel && sel.channel? && !s.modechannelname?
        target = sel.name
      else
        target = s.token!
      end
      command = cmd.to_s
      if command =~ /^(de|un)/
        sign = '-'
        command[0..1] = ''
      else
        sign = '+'
      end
      params = s.split(/ +/)
      if params.empty?
        if cmd == :ban
          s = '+b'
        else
          return true
        end
      else
        s = sign + command[0,1] * params.size + ' ' + s
      end
      cmd = :mode
    when :umode
      cmd = :mode
      s = @mynick + ' ' + s
    end
    
    # cut colon
    if s[0] == ?:
      cut_colon = true
      s[0] = ''
    else
      cut_colon = false
    end
    
    # process text commands
    if cmd == :privmsg || cmd == :notice
      if s[0] == 0x1
        cmd = cmd == :privmsg ? :ctcp : :ctcpreply
        s[0] = ''
        n = s.index("\x01")
        s = s[0...n] if n
      end
    end
    if cmd == :ctcp
      t = s.dup
      subcmd = t.token!
      if subcmd.downcase == 'action'
        cmd = :action
        s = t
        target = s.token!
      end
    end

    # finally action
    case cmd
    when :privmsg,:notice,:action
      return false unless target
      return false if s.empty?
      s = to_local_encoding(to_common_encoding(s))
      
      loop do
        break if s.empty?
        t = truncate_text(s, cmd, target)
        break if t.empty?
        
        targets = target.split(/,/)
        
        targets.each do |chname|
          next if chname.empty?
          
          # support for @#channel
          #
          if chname =~ /^@/
            chname.replace($~.post_match)
            op_prefix = true
          else
            op_prefix = false
          end
          
          c = find_channel(chname)
          if !c && !chname.channelname? && !eq(chname, 'NickServ') && !eq(chname, 'ChanServ')
            c = @world.create_talk(self, chname)
          end
          print_both(c || chname, cmd, @mynick, t)
          
          # support for @#channel and omsg/onotice
          #
          if chname.channelname?
            if opmsg || op_prefix
              chname.replace("@#{chname}")
            end
          end
        end
        
        if cmd == :action
          cmd = :privmsg
          t = "\x01ACTION #{t}\x01"
        end
        
        send(cmd, targets.join(','), t)
      end
    
    when :ctcp
      subcmd = s.token!
      unless subcmd.empty?
        target = s.token!
        if subcmd.downcase == 'ping'
          send_ctcp_ping(target)
        else
          send_ctcp_query(target, "#{subcmd} #{s}")
        end
      end
    when :ctcpreply
      target = s.token!
      send_ctcp_reply(target, s)
    when :quit
      quit(s)
    when :nick
      change_nick(s.token!)
    when :topic
      if s.empty? && !cut_colon
        send(cmd, target)
      else
        send(cmd, target, s)
      end
    when :part
      send(cmd, target, s)
    when :kick
      peer = s.token!
      send(:kick, target, peer, s)
    when :away
      send(cmd, s)
    when :join,:mode,:invite
      send(cmd, target, s)
    when :whois
      if s.include?(' ')
        send(cmd, s)
      else
        send(cmd, "#{s} #{s}")
      end
    else
      s = ':' + s if cut_colon
      send_raw(cmd, s)
    end
    true
  end
  
  
  # model
  
  def number_of_children
    @channels.size
  end
  
  def child_at(index)
    @channels[index]
  end
  
  def label
    if !@cached_label || !@cached_label.isEqualToString?(name)
      @cached_label = name.to_ns
    end
    @cached_label
  end
  
  
  def find_channel(chname)
    @channels.find {|c| eq(c.name, chname) }
  end
  
  def find_channel_by_id(cid)
    @channels.find {|c| c.uid == cid }
  end
  
  def update_unit_title
    @world.update_unit_title(self)
  end
  
  def update_channel_title(channel)
    @world.update_channel_title(channel)
  end
  
  
  def change_nick(tonick)
    @sentnick = @inputnick = tonick
    send(:nick, @inputnick)
  end
  
  def send_whois(nick)
    send(:whois, nick, nick)
  end
  
  def send_file(nick, port, fname, size)
    morph_fname = fname.gsub(/ /, '_')
    if /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\z/ =~ @myaddress
      w, x, y, z = $1.to_i, $2.to_i, $3.to_i, $4.to_i
      addr = w; addr <<= 8
      addr |= x; addr <<= 8
      addr |= y; addr <<= 8
      addr |= z
    else
      addr = @myaddress
    end
    send_ctcp_query(nick, 'DCC SEND', "#{morph_fname} #{addr} #{port} #{size} 2 :#{fname}")
    print_both(self, :dcc_send_send, "Trying file transfer to #{nick}, #{fname} (#{size.grouped_by_comma} bytes) #{@myaddress}:#{port}")
  end
  
  def send_ctcp_ping(target)
    n = Time.now
    i = n.to_i * 1000000 + n.usec
    send_ctcp_query(target, :ping, i.to_s)
  end
  
  def send_ctcp_query(target, cmd, body=nil)
    cmd = cmd.to_s.upcase
    s = "\x01#{cmd}"
    s << " #{body}" if body && !body.empty?
    s << "\x01"
    send(:privmsg, target, s)
  end
  
  def send_ctcp_reply(target, cmd, body=nil)
    cmd = cmd.to_s.upcase
    s = "\x01#{cmd}"
    s << " #{body}" if body && !body.empty?
    s << "\x01"
    send(:notice, target, s)
  end
  
  def send(command, *args)
    return unless connected?
    m = IRCSendingMessage.new(command, *args)
    if block_given?
      yield m
    end
    m.apply! {|i| to_common_encoding(i) }
    m.penalty = Penalty::INIT unless login?
    @conn.send(m)
  end
  
  def send_raw(*args)
    send(*args) {|m| m.complete_colon = false }
  end
  
  
  # timer
  
  def on_timer
    if login?
      check_quitting
      check_pong
      # 437 rejoin
      unless @who_queue.empty?
        @who_wait -= 1 if @who_wait > 0
        if @who_wait == 0 && ready_to_send?
          chname = @who_queue.shift
          c = find_channel(chname)
          if c && c.active?
            send(:who, c.name)
            @who_wait = WHO_TIME
          end
        end
      end
    elsif connecting? || connected?
      check_retry
    elsif @connect_delay
      check_delayed_connect
    else
      check_reconnect
    end
    
    unless @timer_queue.empty?
      q = @timer_queue
      q.each {|i| i[0] -= 1}
      q, @timer_queue = q.partition {|i| i[0] <= 0}
      q.each do |i|
        s = i[2]
        sel = i[1]
        s = $~.post_match if s =~ /\A\//
        send_command(s, true, sel)
      end
    end
    
    @channels.each {|c| c.on_timer}
  end
  
  def check_quitting
    if @quitting && @quit_timer > 0
      @quit_timer -= 1
      if @quit_timer <= 0
        disconnect
      end
    end
  end
  
  def check_reconnect
    if @reconnect && @reconnect_timer > 0
      @reconnect_timer -= 1
      if @reconnect_timer <= 0
        connect(:reconnect)
      end
    end
  end
  
  def check_retry
    if @retry && @retry_timer > 0
      @retry_timer -= 1
      if @retry_timer <= 0
        disconnect
        connect(:retry)
      end
    end
  end
  
  def check_pong
    @pong_timer -= 1
    if @pong_timer < 0
      @pong_timer = PONG_TIME
      send(:pong, @server_hostname)
    end
  end
  
  def check_delayed_connect
    if @connect_delay && @connect_delay > 0
      @connect_delay -= 1
      if @connect_delay <= 0
        @connect_delay = nil
        connect
      end
    end
  end

  def preferences_changed
    if @address_detection_method != preferences.dcc.address_detection_method
      @address_detection_method = preferences.dcc.address_detection_method
      @myaddress = nil
      case @address_detection_method
      when Preferences::Dcc::ADDR_DETECT_JOIN
        @resolver.resolve(@join_address) if @join_address
      when Preferences::Dcc::ADDR_DETECT_SPECIFY
        @resolver.resolve(preferences.dcc.myaddress)
      end
    elsif @address_detection_method == Preferences::Dcc::ADDR_DETECT_SPECIFY
      @resolver.resolve(preferences.dcc.myaddress)
    end
    @log.max_lines = preferences.general.max_log_lines
    @channels.each {|c| c.preferences_changed}
  end
  
  def date_changed
    @channels.each {|c| c.date_changed}
  end

  # whois dialogs
  
  def create_whois_dialog(nick, username, address, realname)
    d = find_whois_dialog(nick)
    if d
      d.show
      return d
    end
    d = WhoisDialog.alloc.init
    d.delegate = self
    @whois_dialogs << d
    d.start(nick, username, address, realname)
    d
  end
  
  def find_whois_dialog(nick)
    @whois_dialogs.find {|d| d.nick == nick }
  end
  
  def whoisDialog_onClose(sender)
    @whois_dialogs.delete(sender)
  end
  
  def whoisDialog_onTalk(sender, nick)
    c = @world.create_talk(self, nick)
    @world.select(c)
  end
  
  def whoisDialog_onUpdate(sender, nick)
    send_whois(nick)
  end
  
  def whoisDialog_onJoin(sender, channel)
    send(:join, channel)
  end
  
  # channel list dialog
  
  def create_channel_list_dialog
    unless @list_dialog
      @list_dialog = ListDialog.alloc.init
      @list_dialog.delegate = self
      @list_dialog.start
    else
      @list_dialog.show
    end
  end
  
  def listDialog_onClose(sender)
    @list_dialog = nil
  end
  
  def listDialog_onUpdate(sender)
    @list_dialog.clear if @list_dialog
    send(:list)
  end
  
  def listDialog_onJoin(sender, chname)
    send(:join, chname)
  end
  
  # socket
  
  def ircsocket_on_connect
    print_system_both(self, 'Connected')
    @connecting = @login = false
    @connected = @reconnect = true
    @encoding = @config.encoding
    @inputnick = @sentnick = @mynick = @config.nick
    @isupport.reset
    mymode = 0
    mymode += 8 if @config.invisible
    send(:pass, @config.password) if @config.password && !@config.password.empty?
    send(:nick, @sentnick)
    send(:user, @config.username, mymode.to_s, '*', ":#{@config.realname}")
    update_unit_title
  end
  
  def ircsocket_on_disconnect
    change_state_to_off
  end
  
  def ircsocket_on_receive(s)
    if @encoding == NSUTF8StringEncoding &&
        @config.fallback_encoding != NSUTF8StringEncoding &&
        !StringValidator::valid_utf8?(s)
      use_fallback = true
    else
      use_fallback = false
    end
    
    s = to_local_encoding(s, use_fallback)
    s = StringValidator::validate_utf8(s)
    m = IRCReceivedMessage.new(s)
    #puts m.to_s
    
    if m.numeric_reply > 0
      receive_numeric_reply(m)
    else
      case m.command
      when :privmsg,:notice; receive_privmsg_and_notice(m)
      when :join; receive_join(m)
      when :part; receive_part(m)
      when :kick; receive_kick(m)
      when :quit; receive_quit(m)
      when :kill; receive_kill(m)
      when :nick; receive_nick(m)
      when :mode; receive_mode(m)
      when :topic; receive_topic(m)
      when :invite; receive_invite(m)
      when :ping; receive_ping(m)
      when :error; receive_error(m)
      when :wallops; receive_wallops(m)
      end
    end
  end
  
  def ircsocket_on_send(m)
    if m.command != :pong
      m.apply! {|i| to_local_encoding(i) }
      print_debug(:debug_send, m.to_s)
    end
  end
  
  def ircsocket_on_error(err)
    print_error(err)
  end
  
  def hostResolver_didResolve(sender, host)
    addrs = host.addresses
    if addrs && addrs.count > 0
      @myaddress = host.addresses.to_a[0].to_s
    else
      @myaddress = nil
    end
  end
  
  def hostResolver_didNotResolve(sender, hostname)
    @myaddress = nil
  end
  
  def print_error(text)
    print_both(self, :error, text)
  end
  
  
  private
  
  def to_common_encoding(s)
    return s.dup if @encoding == NSUTF8StringEncoding
    data = s.to_ns.dataUsingEncoding_allowLossyConversion(@encoding, true)
    s = data ? data.rubyString : ''
    s = KanaSupport::iso2022_to_native(s) if @encoding == NSISO2022JPStringEncoding
    s
  end
  
  def to_local_encoding(s, use_fallback=false)
    enc = @encoding
    if enc == NSUTF8StringEncoding
      if use_fallback
        enc = @config.fallback_encoding
      else
        return s.dup
      end
    end
    s = KanaSupport::to_iso2022(s) if enc == NSISO2022JPStringEncoding
    NSString.stringWithCString_encoding(s, enc).to_s
  end
  
  def reload_tree
    @world.reload_tree
  end
  
  # print
  
  def need_print_console?(channel)
    channel = nil if channel && channel.is_a?(String)
    channel ||= self
    return false if !channel.unit? && !channel.config.console
    channel != @world.selected || !channel.log.viewing_bottom?
  end
  
  def now
    format = preferences.theme.override_timestamp_format ? preferences.theme.timestamp_format : '%H:%M'
    Time.now.strftime(format)
  end
  
  def format_nick(channel, nick)
    format = preferences.theme.override_nick_format ? preferences.theme.nick_format : @world.view_theme.other.log_nick_format
    s = format.gsub(/%@/) do |i|
      mark = ''
      if channel && !channel.unit? && channel.channel?
        m = channel.find_member(nick)
        mark = m.mark if m
      end
      mark.empty? ? ' ' : mark
    end
    s.gsub(/%(-?\d*)n/) do |i|
      if $1
        i = $1.to_i
        if i >= 0
          pad = i - nick.size
          pad > 0 ? (nick + ' ' * pad) : nick
        else
          pad = -i - nick.size
          pad > 0 ? (' ' * pad + nick) : nick
        end
      else
        nick
      end
    end
  end
  
  def print_console(channel, kind, nick, text=nil, identified=nil)
    # adjust parameters when nick is omitted
    if nick && !text
      text = nick
      nick = nil
    end
    
    time = "#{now} "
    if channel && channel.is_a?(String)
      chname = channel
      channel = self
    elsif channel.nil? || channel.unit?
      chname = nil
    else
      chname = channel.name
    end
    if chname && chname.channelname?
      #place = "<#{self.name}:#{chname}> "
      place = "<#{chname}> "
    else
      place = "<#{self.name}> "
    end
    if nick && !nick.empty?
      if kind == :action
        nickstr = "#{nick} "
      else
        nickstr = format_nick(channel, nick)
      end
    else
      nickstr = nil
    end
    if nick && eq(nick, @mynick)
      mtype = :myself
    else
      mtype = :normal
    end
    if !channel
      click = nil
    elsif channel.unit? || channel.is_a?(String)
      click = "unit #{self.uid}"
    else
      click = "channel #{self.uid} #{channel.uid}"
    end
    
    color_num = 0
    if nick && channel && !channel.unit?
      m = channel.find_member(nick)
      if m
        color_num = m.color_number
      end
    end
    
    line = LogLine.new(time, place, nickstr, text, kind, mtype, nick, click, identified, color_num)
    @world.console.print(line, self)
  end
  
  def print_channel(channel, kind, nick, text=nil, identified=nil)
    # adjust parameters when nick is omitted
    if nick && !text
      text = nick
      nick = nil
    end
    
    time = "#{now} "
    if channel && channel.is_a?(String)
      chname = channel
      channel = nil
    else
      chname = nil
    end
    if chname
      place = "<#{chname}> "
    else
      place = nil
    end
    if nick && !nick.empty?
      if kind == :action
        nickstr = "#{nick} "
      else
        nickstr = format_nick(channel, nick)
      end
    else
      nickstr = nil
    end
    if nick && eq(nick, @mynick)
      mtype = :myself
    else
      mtype = :normal
    end
    click = nil
    
    color_num = 0
    if nick && channel && !channel.unit?
      m = channel.find_member(nick)
      if m
        color_num = m.color_number
      end
    end
    
    line = LogLine.new(time, place, nickstr, text, kind, mtype, nick, click, identified, color_num)
    if channel && !channel.unit?
      key = channel.print(line)
    else
      key = @log.print(line, self)
    end
    key
  end
  
  def print_both(channel, kind, nick, text=nil, identified=nil)
    r = print_channel(channel, kind, nick, text, identified)
    if need_print_console?(channel)
      print_console(channel, kind, nick, text, identified)
    end
    r
  end
  
  def print_system(channel, text)
    print_channel(channel, :system, text)
  end
  
  def print_system_both(channel, text)
    print_both(channel, :system, text)
  end
  
  def print_reply(m)
    text = m.sequence(1)
    print_both(self, :reply, text)
  end
  
  def print_unknown_reply(m)
    text = "Reply(#{m.command}): #{m.sequence(1)}"
    print_both(self, :reply, text)
  end
  
  def print_error_reply(m, target=self)
    text = "Error(#{m.command}): #{m.sequence(1)}"
    print_both(target, :error_reply, text)
  end
  
  def print_debug(command, text)
    print_channel(self, command, text)
  end
  
  def set_keyword_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.keyword
    t.keyword = true
    reload_tree
    NSApp.requestUserAttention(NSInformationalRequest) unless NSApp.isActive
    @world.update_icon
  end
  
  def set_unread_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.unread
    t.unread = true
    reload_tree
    @world.update_icon
  end
  
  def set_newtalk_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.newtalk
    t.newtalk = true
    reload_tree
    NSApp.requestUserAttention(NSInformationalRequest) unless NSApp.isActive
    @world.update_icon
  end
  
  def notify_text(kind, c, nick, text)
    return if c && !c.is_a?(String) && !c.config.growl
    title = if c
      if c.is_a?(String)
        c
      else
        c.name
      end
    else
      name
    end
    desc = "<#{nick}> #{text}"
    context = "#{@uid}"
    context << ";#{c.uid}" if c && c.is_a?(IRCChannel)
    @world.notify_on_growl(kind, title, desc, context)
  end
  
  def notify_event(kind, c=nil, nick=nil, text=nil)
    case kind
    when :login
      title = "#{name}"
      desc = "#{@conn.host}:#{@conn.port}"
    when :disconnect
      title = "#{name}"
      desc = ''
    when :kicked
      return unless c.config.growl
      title = "#{c.name}"
      desc = "#{nick} has kicked out you from the channel: #{text}"
    when :invited
      title = "#{name}"
      desc = "#{nick} has invited to #{text}"
    else
      return
    end
    context = "#{@uid}"
    context << ";#{c.uid}" if c && c.is_a?(IRCChannel)
    @world.notify_on_growl(kind, title, desc, context)
  end
  
  def check_rejoin(c)
    return unless preferences.general.auto_rejoin
    return unless c
    return unless c.channel?
    return if c.op?
    return if @mymode.r
    return if c.count_members > 1
    return unless c.name.modechannelname?
    return if c.mode.a
    
    pass = c.mode.k
    pass = nil if pass.empty?
    topic = c.topic
    topic = nil if topic.empty?
    
    part_channel(c)
    c.stored_topic = topic
    join_channel(c, pass, true)
  end
  
  def expand_variables(s)
    s.gsub(/\$nick/, @mynick)
  end
  
  
  # protocol
  
  def receive_init(m)
    return if login?
    @world.expand_unit(self)
    @login = true
    @trying_nick = -1
    @pong_timer = PONG_TIME
    @server_hostname = m.sender
    @mynick = m[0]
    @mymode.clear
    @who_queue = []
    @who_wait = 0
    @in_list = false
    print_system(self, 'Logged in')
    notify_event(:login)
    SoundPlayer.play(preferences.sound.login)
    
    send(:privmsg, 'NickServ', 'IDENTIFY ' + @config.nickPassword) if @config.nickPassword && !@config.nickPassword.empty?
    
    @config.login_commands.each do |s|
      s = s.dup
      s = $~.post_match if /^\// =~ s
      s = expand_variables(s)
      send_command(s, false)
    end
    
    @channels.each do |c|
      if c.channel?
        c.stored_topic = nil
      elsif c.talk?
        c.activate
        c.add_member(User.new(@mynick))
        c.add_member(User.new(c.name))
      end
    end
    update_unit_title
    reload_tree
    
    if !@last_selected_channel && !@channels.empty?
      @last_selected_channel = @channels[0]
    end
    
    ary = @channels.select {|c| c.channel? && c.config.auto_join }
    join_channels(ary)
  end
  
  def join_channels(chans)
    ary = []
    state = :pass
    chans.each do |c|
      haspass = !c.password.empty?
      case state
      when :nopass
        if haspass
          do_quick_join(ary)
          ary = []
          state = :pass
        end
        ary << c
      when :pass
        state = haspass ? :pass : :nopass
        ary << c
      end
      if ary.size >= 10
        do_quick_join(ary)
        ary = []
        state = :pass
      end
    end
    do_quick_join(ary) unless ary.empty?
  end
  
  def do_quick_join(chans)
    target = ''
    pass = ''
    chans.each do |c|
      org_target = target.dup
      org_pass = pass.dup
      
      target << ',' unless target.empty?
      target << c.name
      unless c.password.empty?
        pass << ',' unless pass.empty?
        pass << c.password
      end
      
      common = to_common_encoding(target + pass)
      if common.size > IRC::BODY_LEN
        unless org_target.empty?
          send(:join, org_target, org_pass)
          target = c.name
          pass = c.password
        else
          send(:join, c.name, c.password)
          target = ''
          pass = ''
        end
      end
    end
    send(:join, target, pass) unless target.empty?
  end
  
  def change_state_to_off
    prev_connected = @connected
    @conn = nil
    @connecting = @connected = @login = @quitting = false
    @mynick = @sentnick = ''
    @trying_nick = -1
    @join_address = nil
    @mymode.clear
    @in_whois = false
    @identify_msg = false
    @identify_ctcp = false
    @timer_queue = []
    
    @channels.each do |c|
      if c.channel? || c.talk?
        if c.active?
          c.deactivate
          print_system(c, 'Disconnected')
        end
      end
    end
    
    update_unit_title
    reload_tree
    print_system_both(self, 'Disconnected')
    
    if prev_connected
      notify_event(:disconnect)
      SoundPlayer.play(preferences.sound.disconnect)
    end
  end
  
  def receive_privmsg_and_notice(m)
    text = m[1]
    
    identified = false
    if @identify_ctcp && /\A([+-])\x01/ =~ text || @identify_msg && /\A([+-])/ =~ text
      identified = true if $1 == '+'
      text = text[1..-1]
    end
    
    if /\A\x01([^\x01]*)/ =~ text
      text = $1
      if m.command == :privmsg
        if /\AACTION /i =~ text
          receive_text(m, :action, $~.post_match, identified)
        else
          receive_ctcp_query(m, text)
        end
      else
        receive_ctcp_reply(m, text)
      end
    else
      receive_text(m, m.command, text, identified)
    end
  end
  
  def receive_text(m, command, text, identified)
    # Do we need to log somewhere that we ignored a line?
    return if preferences.keyword.ignore_words.any? { |w| text.include?(w) }
    
    nick = m.sender_nick
    target = m[0]
    
    # support for @#channel
    #
    if target =~ /^@/
      target = $~.post_match
    end
    
    if target.channelname?
      # channel
      c = find_channel(target)
      key = print_both(c || target, command, nick, text, identified)
      if command == :notice
        notify_text(:channelnotice, c || target, nick, text)
      else
        t = c || self
        set_unread_state(t)
        set_keyword_state(t) if key
        kind = :channeltext
        kind = :highlight if key
        notify_text(kind, c || target, nick, text)
        sound = kind == :highlight ? preferences.sound.highlight : preferences.sound.channeltext
        SoundPlayer.play(sound)
        
        if c
          # track the conversation to auto-complete
          sender = c.find_member(nick)
          if sender
            pattern = Regexp.escape(@mynick.sub(/\A_+/, '').sub(/_+\z/, ''))
            if text =~ /#{pattern}/i
              # if we're being directly spoken to
              sender.outgoing_conversation!
            else
              # the other conversations
              sender.conversation!
            end
          end
        end
      end
    elsif eq(target, @mynick)
      if nick.server? || nick.empty?
        # system
        print_both(self, command, nick, text)
      else
        # talk
        c = find_channel(nick)
        newtalk = false
        if !c && command != :notice
          c = @world.create_talk(self, nick)
          newtalk = true
        end
        key = print_both(c || self, command, nick, text, identified)
        if command == :notice
          notify_text(:talknotice, c || nick, nick, text)
        else
          t = c || self
          set_unread_state(t)
          set_newtalk_state(t) if newtalk
          set_keyword_state(t) if key
          kind = :talktext
          if key
            kind = :highlight
          elsif newtalk
            kind = :newtalk
          end
          notify_text(kind, c || nick, nick, text)
          sound = case kind
          when :highlight; preferences.sound.highlight
          when :newtalk; preferences.sound.newtalk
          else; preferences.sound.talktext
          end
          SoundPlayer.play(sound)
        end
      end
    else
      # system
      print_both(self, command, nick, text)
    end
  end
  
  def receive_join(m)
    nick = m.sender_nick
    chname = m[0]
    myself = eq(nick, @mynick)
    
    # workaround for ircd 2.9.5 NJOIN
    njoin = false
    if /\x07o$/ =~ chname
      njoin = true
      chname.sub!(/\x07o$/, '')
    end
    
    c = find_channel(chname)
    if myself
      unless c
        c = @world.create_channel(self, IRCChannelConfig.new({:name => chname}))
        @world.save
      end
      c.activate
      reload_tree
      print_system(c, "You have joined the channel")
      unless @join_address
        @join_address = m.sender_address
        if @address_detection_method == Preferences::Dcc::ADDR_DETECT_JOIN
          @resolver.resolve(@join_address)
        end
      end
    end
    if c && !c.mode.a
      c.add_member(User.new(nick, m.sender_username, m.sender_address, false, false, njoin))
      update_channel_title(c)
    end
    if preferences.general.show_join_leave
      print_both(c || chname, :join, "#{nick} has joined (#{m.sender_username}@#{m.sender_address})")
    end
    check_autoop(c, m.sender_nick, m.sender) unless myself
    
    # add member to talk
    c = find_channel(nick)
    if c
      c.add_member(User.new(nick, m.sender_username, m.sender_address))
    end
  end
  
  def receive_part(m)
    nick = m.sender_nick
    chname = m[0]
    comment = m[1]
    
    myself = false
    c = find_channel(chname)
    if c
      if eq(nick, @mynick)
        myself = true
        c.deactivate
        reload_tree
      end
      c.remove_member(nick)
      update_channel_title(c)
      check_rejoin(c) unless myself
    end
    if preferences.general.show_join_leave
      print_both(c || chname, :part, "#{nick} has left (#{comment})")
    end
    print_system(c, "You have left the channel") if myself
  end
  
  def receive_kick(m)
    nick = m.sender_nick
    chname = m[0]
    target = m[1]
    comment = m[2]
    
    myself = false
    c = find_channel(chname)
    if c
      if eq(target, @mynick)
        myself = true
        c.deactivate
        reload_tree
        print_system_both(c, "You have been kicked out from the channel")
        notify_event(:kicked, c, nick, comment)
        SoundPlayer.play(preferences.sound.kicked)
        
        # rejoin
        join_channel(c, c.mode.k) unless eq(nick, @mynick)
      end
      c.remove_member(target)
      update_channel_title(c)
      check_rejoin(c) unless myself
    end
    print_both(c || chname, :kick, "#{nick} has kicked #{target} (#{comment})")
  end
  
  def receive_quit(m)
    nick = m.sender_nick
    comment = m[0]
    
    @channels.each do |c|
      if c.find_member(nick)
        if preferences.general.show_join_leave
          print_channel(c, :quit, "#{nick} has left IRC (#{comment})")
        end
        c.remove_member(nick)
        update_channel_title(c)
        check_rejoin(c)
      end
    end
    if preferences.general.show_join_leave
      print_console(nil, :quit, "#{nick} has left IRC (#{comment})")
    end
  end
  
  def receive_kill(m)
    sender = m.sender_nick
    sender = m.sender if !sender || sender.empty?
    target = m[0]
    comment = m[1]
    
    @channels.each do |c|
      if c.find_member(target)
        print_channel(c, :kill, "#{sender} has made #{target} to leave IRC (#{comment})")
        c.remove_member(target)
        update_channel_title(c)
        check_rejoin(c)
      end
    end
    print_console(nil, :kill, "#{sender} has made #{target} to leave IRC (#{comment})")
  end
  
  def receive_nick(m)
    nick = m.sender_nick
    tonick = m[0]
    
    if eq(nick, @mynick)
      # changed mynick
      @mynick = tonick
      update_unit_title
      print_channel(self, :nick, "You are now known as #{tonick}")
    end
    
    @channels.each do |c|
      if c.find_member(nick)
        # rename channel member
        print_channel(c, :nick, "#{nick} is now known as #{tonick}")
        c.rename_member(nick, tonick)
      end
    end
    
    c = find_channel(nick)
    if c
      t = find_channel(tonick)
      if t
        # there is already a channel for tonick
        # remove it
        @world.destroy_channel(t)
      end
      
      # rename talk
      c.name = tonick
      reload_tree
      update_channel_title(c)
    end
    
    # rename nick on whois dialog
    @whois_dialogs.select {|i| i.nick == nick}.each {|i| i.nick = tonick}
    
    # rename nick in dcc
    @world.dcc.nick_changed(self, nick, tonick)
    
    print_console(nil, :nick, "#{nick} is now known as #{tonick}")
  end
  
  def receive_mode(m)
    nick = m.sender_nick
    target = m[0]
    modestr = m.sequence(1).rstrip
    
    if target.channelname?
      # channel mode
      c = find_channel(target)
      if c
        prev_a = c.mode.a
        info = c.mode.update(modestr)
        
        # enter/leave anonymous mode
        if c.mode.a != prev_a
          if c.mode.a
            me = c.find_member(@mynick)
            c.clear_members
            c.add_member(me)
          else
            c.who_init = false
            send(:who, c.name)
          end
        end
        
        info.each do |h|
          next unless h[:op_mode]
          
          # process op modes
          mode = h[:mode]
          plus = h[:plus]
          t = h[:param]
          
          myself = false
          if (mode == :q || mode == :a || mode == :o) && eq(t, @mynick)
            # mode change for myself
            m = c.find_member(t)
            if m
              myself = true
              prev = m.op?
              c.change_member_op(t, mode, plus)
              c.op = m.op?
              if !prev && c.op? && c.who_init
                check_all_autoop(c)
              end
            end
          end
          c.change_member_op(t, mode, plus) unless myself
        end
        
        update_channel_title(c)
      end
      print_both(c || target, :mode, "#{nick} has changed mode: #{modestr}")
    else
      # user mode
      @mymode.update(modestr)
      print_both(self, :mode, "#{nick} has changed mode: #{modestr}")
      update_unit_title
    end
  end
  
  def receive_topic(m)
    nick = m.sender_nick
    chname = m[0]
    topic = m[1]
    
    c = find_channel(chname)
    if c
      c.topic = topic
      update_channel_title(c)
    end
    print_both(c || chname, :topic, "#{nick} has set topic: #{topic}")
  end
  
  def receive_invite(m)
    sender = m.sender_nick
    chname = m[1]
    print_both(self, :invite, "#{sender} has invited you to #{chname}")
    notify_event(:invited, nil, sender, chname)
    SoundPlayer.play(preferences.sound.invited)
  end
  
  def receive_ping(m)
    @pong_timer = PONG_TIME
    send(:pong, m.sequence)
  end
  
  def receive_error(m)
    comment = m[0]
    print_error("Error: #{comment}")
  end
  
  def receive_wallops(m)
    sender = m.sender_nick
    sender = m.sender if !sender || sender.empty?
    comment = m[0]
    print_both(self, :wallops, "Wallops: #{comment}")
  end
  
  def receive_ctcp_query(m, text)
    nick = m.sender_nick
    text = text.dup
    
    command = text.token!
    return if command.empty?
    cmd = command.downcase.to_sym
    case cmd
    when :dcc
      kind = text.token!
      unless kind.empty?
        case kind.downcase.to_sym
        when :send
          if text =~ /^\"([^\"]+)\"/
            fname = $1
            text = $~.post_match
          else
            fname = text.token!
          end
          addr = text.token!
          port = text.token!.to_i
          size = text.token!.to_i
          ver = text.token!.to_i
          lfname = text
          if ver >= 2
            lfname[0] = '' if lfname[0] == ?:
            fname = lfname unless lfname.empty?
          end
          receive_dcc_send(m, fname, addr, port, size, ver)
          return
        end
      end
      print_both(self, :reply, "CTCP-query unknown(DCC #{kind}) from #{nick} : #{text}")
    else
      if @last_ctcp && (Time.now - @last_ctcp < 4)
        @last_ctcp = Time.now
        print_both(self, :reply, "CTCP-query #{command} from #{nick} was ignored")
        return
      end
      @last_ctcp = Time.now
      
      case cmd
      when :ping
        send_ctcp_reply(nick, command, text)
      when :time
        send_ctcp_reply(nick, command, Time.now.to_s)
      when :version
        name = NSBundle.mainBundle.infoDictionary[:LCApplicationName].to_s
        ver = NSBundle.mainBundle.infoDictionary[:CFBundleShortVersionString].to_s
        s = "#{name} #{ver}"
        send_ctcp_reply(nick, command, s)
      when :userinfo
        send_ctcp_reply(nick, command, @config.userinfo)
      when :clientinfo
        send_ctcp_reply(nick, command, _('CtcpClientInfo').to_s)
      else
        print_both(self, :reply, "CTCP-query unknown(#{command}) from #{nick}")
        return
      end
      print_both(self, :reply, "CTCP-query #{command} from #{nick}")
    end
  end
  
  def receive_dcc_send(m, fname, addr, port, size, ver)
    return unless eq(m[0], @mynick)
    
    if /^\d+$/ =~ addr
      a = addr.to_i
      w = a & 0xff; a >>= 8
      x = a & 0xff; a >>= 8
      y = a & 0xff; a >>= 8
      z = a & 0xff
      host = "#{z}.#{y}.#{x}.#{w}"
    else
      host = addr
    end
    print_both(self, :dcc_send_receive, "Received file transfer request from #{m.sender_nick}, #{fname} (#{size.grouped_by_comma} bytes) #{host}:#{port}")
    
    if preferences.dcc.action != Preferences::Dcc::ACTION_IGNORE
      if port > 0 && size > 0
        if Pathname.new('~/Downloads').expand_path.exist?
          path = '~/Downloads'
        else
          path = '~/Desktop'
        end
        @world.dcc.add_receiver(@uid, m.sender_nick, host, port, path, fname, size, ver)
        SoundPlayer.play(preferences.sound.file_receive_request)
        @world.notify_on_growl(:file_receive_request, m.sender_nick, fname)
        NSApp.requestUserAttention(NSInformationalRequest) unless NSApp.isActive
      end
    end
  end
  
  def receive_ctcp_reply(m, text)
    nick = m.sender_nick
    text = text.dup
    command = text.token!
    return if command.empty?
    case command.downcase.to_sym
    when :ping
      if /^\d+$/ =~ text
        n = Time.now
        i = n.to_i * 1000000 + n.usec
        d = i - text.to_i
        d /= 1000
        msec = d % 1000
        sec = d / 1000
        text = sprintf("%d.%02d", sec, msec/10)
        print_both(self, :reply, "CTCP-reply #{command} from #{nick} : #{text} sec")
      else
        print_both(self, :reply, "CTCP-reply #{command} from #{nick} : #{text}")
      end
    else
      print_both(self, :reply, "CTCP-reply #{command} from #{nick} : #{text}")
    end
  end
  
  def receive_numeric_reply(m)
    n = m.numeric_reply
    if 400 <= n && n < 600 && n != 403 && n != 422
      receive_error_numeric_reply(m)
      return
    end
    
    case n
    when 1,376,422
      receive_init(m)
      print_reply(m)
    when 2..4,10,20,42,250..255,265,266,372,375
      print_reply(m)
    when 5  # RPL_ISUPPORT
      @isupport.update(m.sequence(1))
      print_reply(m)
    when 221  # RPL_UMODEIS
      modestr = m[1].rstrip
      return if modestr == '+'
      @mymode.clear
      @mymode.update(modestr)
      update_unit_title
      print_both(self, :reply, "Mode: #{modestr}")
    when 290  # RPL_CAPAB ? on freenode
      kind = m[1]
      case kind.downcase
        when 'identify-msg'; @identify_msg = true
        when 'identify-ctcp'; @identify_ctcp = true
      end
      print_reply(m)
    when 301  # RPL_AWAY
      nick = m[1]
      comment = m[2]
      if @in_whois
        d = find_whois_dialog(nick)
        if d
          d.set_away_message(comment)
          return
        end
      end
      c = find_channel(nick)
      print_both(c || self, :reply, "#{nick} is away: #{comment}")
    when 311	# RPL_WHOISUSER
      @in_whois = true
      nick = m[1]
      username = m[2]
      host = m[3]
      realname = m[5]
      d = create_whois_dialog(nick, username, host, realname)
      unless d
        print_both(self, :reply, "#{nick} is #{realname} (#{username}@#{host})")
      end
    when 312	# RPL_WHOISSERVER
      nick = m[1]
      server = m[2]
      serverinfo = m[3]
      if @in_whois
        d = find_whois_dialog(nick)
        if d
          d.set_server(server, serverinfo)
          return
        end
      end
      print_both(self, :reply, "#{nick} is on #{server} (#{serverinfo})")
    when 313	# RPL_WHOISOPERATOR
      nick = m[1]
      if @in_whois
        d = find_whois_dialog(nick)
        if d
          d.set_operator
          return
        end
      end
      print_both(self, :reply, "#{nick} is an IRC operator")
    when 317	# RPL_WHOISIDLE
      nick = m[1]
      idlestr = m[2]
      signonstr = m[3]
      sec = idlestr.to_i
      if sec > 0
        min = sec / 60
        sec %= 60
        hour = min / 60
        min %= 60
        idle = sprintf('%d:%02d:%02d', hour, min, sec)
      else
        idle = ''
      end
      signon = signonstr.to_i
      if signon > 0
        signon = Time.at(signon).strftime('%Y/%m/%d %H:%M') rescue ''
      else
        signon = ''
      end
      if @in_whois
        d = find_whois_dialog(nick)
        if d
          d.set_time(idle, signon)
          return
        end
      end
      print_both(self, :reply, "#{nick} is #{idle} idle") unless idle.empty?
      print_both(self, :reply, "#{nick} logged in at #{signon}") unless signon.empty?
    when 319	# RPL_WHOISCHANNELS
      nick = m[1]
      trail = m[2]
      channels = trail.split(' ')
      if @in_whois
        d = find_whois_dialog(nick)
        if d
          d.set_channels(channels)
          return
        end
      end
      print_both(self, :reply, "#{nick} is in #{channels.join(', ')}")
    when 318	# RPL_ENDOFWHOIS
      @in_whois = false
    when 324  # RPL_CHANNELMODEIS
      chname = m[1]
      modestr = m.sequence(2).rstrip
      return if modestr == '+'
      c = find_channel(chname)
      if c && c.active?
        prev_a = c.mode.a
        c.mode.clear
        c.mode.update(modestr)
        if c.mode.a != prev_a
          if c.mode.a
            me = c.find_member(@mynick)
            c.clear_members
            c.add_member(me)
          else
            c.who_init = false
            send(:who, c.name)
          end
        end
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "Mode: #{modestr}")
    when 329  # hemp? channel creation time
      chname = m[1]
      timestr = m[2]
      timenum = timestr.to_i
      begin
        time = Time.at(timenum)
        c = find_channel(chname)
        print_both(c || chname, :reply, "Created at: #{time.strftime('%Y/%m/%d %H:%M')}")
      rescue
        ;
      end
    when 331  # RPL_NOTOPIC
      chname = m[1]
      c = find_channel(chname)
      if c && c.active?
        c.topic = ''
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "Topic: ")
    when 332  # RPL_TOPIC
      chname = m[1]
      topic = m[2]
      c = find_channel(chname)
      if c && c.active?
        c.topic = topic
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "Topic: #{topic}")
    when 333  # RPL_TOPIC_WHO_TIME
      chname = m[1]
      setter = m[2]
      timestr = m[3]
      nick = setter[/^[^!@]+/]
      timenum = timestr.to_i
      begin
        time = Time.at(timenum)
        c = find_channel(chname)
        print_both(c || chname, :reply, "#{nick} set the topic at: #{time.strftime('%Y/%m/%d %H:%M')}")
      rescue
        ;
      end
    when 353  # RPL_NAMREPLY
      chname = m[2]
      trail = m[3].strip
      c = find_channel(chname)
      if c && c.active? && !c.names_init
        trail.split(' ').each do |nick|
          if /^([~&@%+])(.+)/ =~ nick
            op, nick = $1, $2
          end
          m = User.new(nick)
          m.q = op == '~'
          m.a = op == '&'
          m.o = op == '@' || m.q
          m.h = op == '%'
          m.v = op == '+'
          c.add_member(m, false)
          c.op = (m.q || m.a || m.o) if eq(m.nick, @mynick)
        end
        c.reload_members
        update_channel_title(c)
      else
        print_both(c || chname, :reply, "Names: #{trail}")
      end
    when 366  # RPL_ENDOFNAMES
      chname = m[1]
      c = find_channel(chname)
      if c && c.active? && !c.names_init
        c.names_init = true
        
        if c.count_members <= 1 && c.op?
          if chname.modechannelname?
            m = c.config.mode
            if m && !m.empty?
              send(:mode, chname, m)
            end
          end
        else
          send(:mode, chname)
        end
        
        if c.count_members <= 1 && chname.modechannelname?
          topic = c.stored_topic
          if topic && !topic.empty?
            send(:topic, chname, topic)
            c.stored_topic = nil
          else
            topic = c.config.topic
            if topic && !topic.empty?
              send(:topic, chname, topic)
            end
          end
        end
        
        if c.count_members > 1
          @who_queue << chname
        else
          c.who_init = true
        end
        
        update_channel_title(c)
      end
    when 352	# RPL_WHOREPLY
      chname = m[1]
      username = m[2]
      address = m[3]
      nick = m[5]
      mode = m[6]
      
      c = find_channel(chname)
      if c && c.active? && !c.who_init
        q = mode.include?('~')
        a = mode.include?('&')
        o = mode.include?('@') || q
        h = mode.include?('%')
        v = mode.include?('+')
        c.update_or_add_member(nick, username, address, q, a, o, h, v)
      else
        print_unknown_reply(m)
      end
    when 315	# RPL_ENDOFWHO
      chname = m[1]
      c = find_channel(chname)
      if c && c.active? && !c.who_init
        c.who_init = true
        c.reload_members
        #print_system(c, "Members list has been initialized")
        check_all_autoop(c) if c.op?
      else
        print_unknown_reply(m)
      end
    when 322	# RPL_LIST
      chname = m[1]
      count = m[2]
      topic = m.sequence(3)
      unless @in_list
        @in_list = true
        if @list_dialog
          @list_dialog.clear
        else
          create_channel_list_dialog
        end
      end
      if @list_dialog
        @list_dialog.add_item([chname, count.to_i, topic])
      else
        print_both(nil, :reply, "#{chname} (#{count}) #{topic}")
      end
    when 323	# RPL_LISTEND
      @in_list = false
      if @list_dialog
        @list_dialog.sort
        @list_dialog.reload_table 
      end
    else
      print_unknown_reply(m)
    end
  end

=begin
when 303	# RPL_ISON
when 305	# RPL_UNAWAY
when 306	# RPL_NOWAWAY
when 314	# RPL_WHOWASUSER
when 369	# RPL_ENDOFWHOWAS
when 341	# RPL_INVITING

when 367	# RPL_BANLIST
when 368	# RPL_ENDOFBANLIST
when 348	# RPL_EXCEPTLIST
when 349	# RPL_ENDOFEXCEPTLIST
when 346	# RPL_INVITELIST
when 347	# RPL_ENDOFINVITELIST
when 344	# RPL_REOPLIST
when 345	# RPL_ENDOFREOPLIST
  
when 403	# ERR_NOSUCHCHANNEL 
=end
  
  def receive_error_numeric_reply(m)
    number = m.numeric_reply
    case number
    when 401
      c = find_channel(m[1])
      if c && c.active?
        print_error_reply(m, c)
        return
      end
    when 433
      receive_nick_collision(m)
    end
    print_error_reply(m)
  end

=begin
when 437	#ERR_UNAVAILRESOURCE 2.10
when 432	#ERR_ERRONEUSNICKNAME 
when 433	#ERR_NICKNAMEINUSE
when 436	#ERR_NICKCOLLISION

if on  
when 405	# ERR_TOOMANYCHANNELS
when 471	# ERR_CHANNELISFULL
when 473	# ERR_INVITEONLYCHAN
when 474	# ERR_BANNEDFROMCHAN
when 475	# ERR_BADCHANNELKEY
when 476	# ERR_BADCHANMASK
when 437	# ERR_UNAVAILRESOURCE 2.10
=end
  
  def receive_nick_collision(m)
    if !@config.alt_nicks.empty? && !@login
      # only works when not login
      @trying_nick += 1
      nick = @config.alt_nicks[@trying_nick]
      if nick
        @sentnick = nick
        send(:nick, nick)
      else
        try_another_nick
      end
    else
      try_another_nick
    end
  end
  
  def try_another_nick
    if @sentnick.size >= @isupport.nicklen
      nick = @sentnick[0...@isupport.nicklen]
      if /^(.+)[^_](_*)$/ =~ nick
        head, tail = $1, $2
        @sentnick = head + tail + '_'
      else
        @sentnick = '0'
      end
    else
      @sentnick = @sentnick + '_'
    end
    send(:nick, @sentnick)
  end
end
