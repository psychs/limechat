# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class IRCUnit < OSX::NSObject
  include OSX
  attr_accessor :world, :pref, :log, :id
  attr_reader :config, :channels, :mynick, :mymode, :encoding, :myaddress
  attr_accessor :property_dialog
  attr_accessor :keyword, :unread
  attr_accessor :last_selected_channel
  
  RECONNECT_TIME = 20
  RETRY_TIME = 240
  PONG_TIME = 300
  QUIT_TIME = 5
  
  def initialize
    @channels = []
    @whois_dialogs = []
    @connected = @login = @quitting = false
    @mynick = @inputnick = @sentnick = ''
    @myaddress = nil
    @join_address = nil
    @encoding = NSISO2022JPStringEncoding
    @mymode = UserMode.new
    @in_whois = false
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
    @address_detection_method = @pref.dcc.address_detection_method
    case @address_detection_method
    when Preferences::Dcc::ADDR_DETECT_NIC
      detect_myaddress_from_nic
    when Preferences::Dcc::ADDR_DETECT_SPECIFY
      Resolver.resolve(self, @pref.dcc.myaddress)
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
    
    ary += @channels.select {|i| !i.channel? }
    remains = @channels.select {|i| i.channel? }
    remains.each {|i| part_channel(i) }
    
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
    ary += @channels.select {|i| i.channel? }
    ary += @channels.select {|i| !i.channel? }
    @channels = ary
  end
  
  def store_config
    u = @config.dup
    u.channels = []
    @channels.each do |c|
      u.channels << c.config.dup if c.channel?
    end
    u
  end
  
  def terminate
    quit
    close_dialog
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
  
  def close_dialog
    if @property_dialog
      @property_dialog.close
      @property_dialog = nil
    end
    @whois_dialogs.each {|d| d.close }
    @whois_dialogs.clear
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
    @conn.host = @config.host
    @conn.port = @config.port.to_i
    @conn.open
  end
  
  def disconnect
    return unless connected?
    @quitting = false
    @reconnect = false
    @conn.close
    change_state_to_off
  end
  
  def quit(comment=nil)
    return disconnect unless login?
    @quitting = true
    @quit_timer = QUIT_TIME
    @reconnect = false
    comment = @config.leaving_comment unless comment
    send(:quit, ":#{comment}")
  end
  
  def cancel_reconnect
    return if connected?
    return unless @reconnect
    @reconnect = false
    print_system(self, 'Stopped reconnecting')
  end
  
  def join_channel(channel)
    return unless login?
    return if channel.active?
    pass = channel.config.password
    pass = nil if pass.empty?
    send(:join, channel.name, pass)
  end
  
  def part_channel(channel, comment=nil)
    return unless login?
    return unless channel.active?
    comment = ":#{@config.leaving_comment}" if !comment && @config.leaving_comment
    send(:part, channel.name, comment)
  end
  
  def input_text(str)
    return false unless login?
    sel = @world.selected
    str.split(/\r\n|\r|\n/).each do |s|
      next if s.empty?
      if s[0] == ?/
        s[0] = ''
        send_command(s)
      elsif sel == self
        send_command(s)
      else
        send_text(sel, :privmsg, s)
      end
    end
    true
  end
  
  def send_text(chan, cmd, str)
    return false unless login? && chan
    str.split(/\r\n|\r|\n/).each do |s|
      next if s.empty?
      print_both(chan, cmd, @mynick, s)
      send(cmd, chan.name, ":#{s}")
    end
    true
  end
  
  def send_command(s)
    return false unless connected?
    command = s.token!
    cmd = command.downcase.to_sym
    case cmd
    when :privmsg,:msg,:notice,:action
      cmd = :privmsg if cmd == :msg
      target = s.token!
      c = find_channel(target)
      print_both(c || target, cmd, @mynick, s)
      if cmd == :action
        cmd = :privmsg
        s = "\x01ACTION #{s}\x01"
      end
      send(cmd, target, ":#{s}")
    when :quit
      quit(s)
    when :nick
      change_nick(s)
    else
      if cmd
        send(cmd, s)
      else
        send(command, s)
      end
    end
    true
  end
  
  
  # model
  
  def number_of_children
    @channels.length
  end
  
  def child_at(index)
    @channels[index]
  end
  
  def label
    name
  end
  
  
  def find_channel(chname)
    @channels.find {|c| eq(c.name, chname) }
  end
  
  def find_channel_by_id(cid)
    @channels.find {|c| c.id == cid }
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
    print_both(self, :dcc_send_send, "*Trying file transfer to #{nick}, #{fname} (#{size.grouped_by_comma} bytes) #{@myaddress}:#{port}")
  end
  
  def send_ctcp_query(target, cmd, body)
    send(:privmsg, target, ":\x01#{cmd} #{body}\x01")
  end
  
  def send_ctcp_reply(target, cmd, body)
    send(:notice, target, ":\x01#{cmd} #{body}\x01")
  end
  
  def send(command, *args)
    return unless connected?
    m = IRCSendMessage.new
    m.command = command if command
    args = args.select {|i| i }
    case args.length
    when 0
      ;
    when 1
      m.trail = args[0]
    else
      m.target = args[0]
      m.trail = args[1..-1].join(' ')
    end
    m.map! {|i| to_common_encoding(i) }
    m.penalty = Penalty::INIT unless login?
    @conn.send(m)
  end
  
  
  # timer
  
  def on_timer
    if login?
      check_quitting
      # who manager
      # 437 rejoin
      check_pong
    elsif connecting? || connected?
      check_retry
    else
      check_reconnect
      check_delayed_connect
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
      send(:pong, ":#{@server_hostname}")
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
    if @address_detection_method != @pref.dcc.address_detection_method
      @address_detection_method = @pref.dcc.address_detection_method
      @myaddress = nil
      case @address_detection_method
      when Preferences::Dcc::ADDR_DETECT_JOIN
        Resolver.resolve(self, @join_address) if @join_address
      when Preferences::Dcc::ADDR_DETECT_NIC
        detect_myaddress_from_nic
      when Preferences::Dcc::ADDR_DETECT_SPECIFY
        Resolver.resolve(self, @pref.dcc.myaddress)
      end
    end
      
    @channels.each {|c| c.preferences_changed}
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
  
  # socket
  
  def ircsocket_on_connect
    print_system_both(self, 'Connected')
    @connecting = false
    @connected = true
    @login = false
    @encoding = @config.encoding
    @inputnick = @sentnick = @mynick = @config.nick
    mymode = 0
    mymode += 8 if @config.invisible
    send(:pass, @config.password) if @config.password && !@config.password.empty?
    send(:nick, @sentnick)
    send(:user, "#{@config.username} #{mymode} * :#{@config.realname}")
    update_unit_title
  end
  
  def ircsocket_on_disconnect
    change_state_to_off
  end
  
  def ircsocket_on_receive(m)
    m.map! {|i| to_local_encoding(i) }
    m.map! {|i| StringValidator::validate_utf8(i, 0x3f) }
    #puts m
    #puts m.params
    
    if m.numeric_reply > 0
      receive_numeric_reply(m)
    else
      case m.command
        when :privmsg; receive_privmsg(m)
        when :notice; receive_notice(m)
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
    m.map! {|i| to_local_encoding(i) }
    print_debug(:debug_send, m.to_s)
  end
  
  def ircsocket_on_error(err)
    print_error(err.localizedDescription.to_s)
  end
  
  def ResolverOnResolve(addr)
    return unless addr
    addr = addr.to_a.map {|i| i.to_s}
    @myaddress = addr[0]
  end
  
  
  private
  
  def to_common_encoding(s)
    return s.dup if @encoding == NSUTF8StringEncoding
    data = NSString.stringWithString(s).dataUsingEncoding(@encoding)
    s = data ? data.bytes.bytestr(data.length) : ''
    s = KanaSupport::iso2022_to_native(s) if @encoding == NSISO2022JPStringEncoding
    s
  end
  
  def to_local_encoding(s)
    return s.dup if @encoding == NSUTF8StringEncoding
    s = KanaSupport::to_iso2022(s) if @encoding == NSISO2022JPStringEncoding
    NSString.stringWithCString_encoding(s, @encoding).to_s
  end
  
  def reload_tree
    @world.reload_tree
  end
  
  def detect_myaddress_from_nic
    addr = Socket.getaddrinfo(Socket.gethostname, nil)
    addr = addr.find {|i| !(/\.local$/ =~ i[2])}
    Resolver.resolve(self, addr[2]) if addr
  end
  
  # print
  
  def need_print_console?(channel)
    channel = nil if channel && channel.kind_of?(String)
    channel ||= self
    return false if !channel.unit? && !channel.config.console
    channel != @world.selected || !channel.log.viewing_bottom?
  end
  
  def print_console(channel, kind, nick, text=nil)
    if nick && !text
      text = nick
      nick = nil
    end
    
    time = "#{now} "
    if channel && channel.kind_of?(String)
      chname = channel
      channel = self
    elsif channel.nil? || channel.unit?
      chname = nil
    else
      chname = channel.name
    end
    place = nil
    if chname && chname.channelname?
      place = "<#{self.name}:#{chname}> "
    else
      place = "<#{self.name}> "
    end
    nickstr = (nick && !nick.empty?) ? "(#{nick}) " : nil
    if nick && eq(nick, @mynick)
      mtype = :myself
    else
      mtype = :normal
    end
    if !channel
      click = nil
      key = true
    elsif channel.unit? || channel.kind_of?(String)
      click = "unit #{self.id}"
      key = true
    else
      click = "channel #{self.id} #{channel.id}"
      key = channel.config.keyword
    end
    
    line = LogLine.new(time, place, nickstr, text, kind, mtype, nick, click)
    @world.console.print(line, key)
  end
  
  def print_channel(channel, kind, nick, text=nil)
    if nick && !text
      text = nick
      nick = nil
    end
    
    time = "#{now} "
    if channel && channel.kind_of?(String)
      chname = channel
      channel = nil
    else
      chname = nil
    end
    place = nil
    if chname
      place = "<#{chname}> "
    end
    nickstr = (nick && !nick.empty?) ? "(#{nick}) " : nil
    if nick && eq(nick, @mynick)
      mtype = :myself
    else
      mtype = :normal
    end
    click = nil
    
    line = LogLine.new(time, place, nickstr, text, kind, mtype, nick, click)
    if channel && !channel.unit?
      key = channel.log.print(line, channel.config.keyword)
      set_keyword_state(channel) if key
    else
      key = @log.print(line, true)
      set_keyword_state(self) if key
    end
  end
  
  def print_both(channel, kind, nick, text=nil)
    r = print_channel(channel, kind, nick, text)
    if need_print_console?(channel)
      print_console(channel, kind, nick, text)
    end
    r
  end
  
  def print_system(channel, text)
    print_channel(channel, :system, text)
  end
  
  def print_system_both(channel, text)
    print_both(channel, :system, text)
  end
  
  def print_error(text)
    print_both(self, :error, text)
  end
  
  def print_reply(m)
    text = m.sequence(1)
    print_both(self, :reply, text)
  end
  
  def print_unknown_reply(m)
    text = "Reply(#{m.command}): #{m.sequence(1)}"
    print_both(self, :reply, text)
  end
  
  def print_error_reply(m)
    text = "Error(#{m.command}): #{m.sequence(1)}"
    print_both(self, :error_reply, text)
  end
  
  def print_debug(command, text)
    print_channel(self, command, text)
  end
  
  def now
    Time.now.strftime('%H:%M')
  end
  
  def set_keyword_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.keyword
    return if !t.unit? && !t.config.keyword
    t.keyword = true
    reload_tree
    NSApp.requestUserAttention(NSCriticalRequest) unless NSApp.isActive
  end
  
  def set_unread_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.unread
    return if !t.unit? && !t.config.unread
    t.unread = true
    reload_tree
  end
  
  def set_newtalk_state(t)
    return if NSApp.isActive && @world.selected == t
    return if t.newtalk
    t.newtalk = true
    reload_tree
    NSApp.requestUserAttention(NSInformationalRequest) unless NSApp.isActive
  end
  
  # protocol
  
  def receive_init(m)
    return if login?
    @world.expand_unit(self)
    @login = true
    @pong_timer = PONG_TIME
    @server_hostname = m.sender
    @mynick = m[0]
    @mymode.clear
    print_system(self, 'Logged in')
    @channels.each do |c|
      if c.talk?
        c.activate
      end
    end
    update_unit_title
    reload_tree
    if !@last_selected_channel && !@channels.empty?
      @last_selected_channel = @channels[0]
    end
    ary = @channels.select {|c| c.config.auto_join }
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
      if ary.length >= 10
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
      target += ',' unless target.empty?
      target += c.name
      pass += ',' unless pass.empty?
      pass += c.password
    end
    send(:join, target, pass)
  end
  
  def change_state_to_off
    @conn = nil
    @connecting = @connected = @login = @quitting = false
    @mynick = @sentnick = ''
    @myaddress = nil
    @join_address = nil
    @mymode.clear
    @in_whois = false
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
  end
  
  def receive_privmsg(m)
    text = m[1]
    if text[0] == 0x1
      text[0] = ''
      n = text.index("\x01")
      text = text[0...n] if n
      receive_ctcp_query(m, text)
    else
      receive_text(m, :privmsg, text)
    end
  end
  
  def receive_notice(m)
    text = m[1]
    if text[0] == 0x1
      text[0] = ''
      n = text.index("\x01")
      text = text[0...n] if n
      receive_ctcp_reply(m, text)
    else
      receive_text(m, :notice, text)
    end
  end
  
  def receive_text(m, command, text)
    nick = m.sender_nick
    target = m[0]
    
    if target.channelname?
      c = find_channel(target)
      print_both(c || target, command, nick, text)
      set_unread_state(c || self) if command != :notice
    elsif eq(target, @mynick)
      if nick.server? || nick.empty?
        print_both(self, command, nick, text)
      else
        # talk
        c = find_channel(nick)
        if !c && command != :notice
          c = @world.create_talk(self, nick)
          set_newtalk_state(c)
        end
        print_both(c || self, command, nick, text)
        set_unread_state(c || self) if command != :notice
      end
    else
      print_both(target, command, nick, text)
      set_unread_state(self) if command != :notice
    end
  end
  
  def receive_join(m)
    nick = m.sender_nick
    chname = m[0]
    
    # workaround for ircd 2.9.5 NJOIN
    njoin = false
    if /\x07o$/ =~ chname
      njoin = true
      chname.sub!(/\x07o$/, '')
    end
    
    c = find_channel(chname)
    if eq(nick, @mynick)
      unless c
        c = @world.create_channel(self, IRCChannelConfig.new({:name => chname}))
        @world.save
      end
      c.activate
      reload_tree
      print_system(c, "You have joined the channel")
      @join_address = m.sender_address unless @join_address
      if @address_detection_method == Preferences::Dcc::ADDR_DETECT_JOIN
        Resolver.resolve(self, @join_address) unless @myaddress
      end
    end
    if c
      c.add_member(User.new(nick, m.sender_username, m.sender_address, njoin))
      update_channel_title(c)
    end
    print_both(c || chname, :join, "*#{nick} has joined (#{m.sender_username}@#{m.sender_address})")
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
    end
    print_both(c || chname, :part, "*#{nick} has left (#{comment})")
    print_system(c, "You have left the channel") if myself
  end
  
  def receive_kick(m)
    nick = m.sender_nick
    chname = m[0]
    target = m[1]
    comment = m[2]
    
    c = find_channel(chname)
    if c
      if eq(target, @mynick)
        c.deactivate
        reload_tree
        print_system_both(c, "You have been kicked out from the channel")
      end
      c.remove_member(target)
      update_channel_title(c)
    end
    print_both(c || chname, :kick, "*#{nick} has kicked #{target} (#{comment})")
  end
  
  def receive_quit(m)
    nick = m.sender_nick
    comment = m[0]
    
    @channels.each do |c|
      if c.find_member(nick)
        print_channel(c, :quit, "*#{nick} has left IRC (#{comment})")
        c.remove_member(nick)
        update_channel_title(c)
      end
    end
    print_console(nil, :quit, "*#{nick} has left IRC (#{comment})")
  end
  
  def receive_kill(m)
    sender = m.sender_nick
    sender = m.sender if !sender || sender.empty?
    target = m[0]
    comment = m[1]
    
    @channels.each do |c|
      if c.find_member(nick)
        print_channel(c, :kill, "*#{sender} has made #{target} to leave IRC (#{comment})")
        c.remove_member(nick)
        update_channel_title(c)
      end
    end
    print_console(nil, :kill, "*#{sender} has made #{target} to leave IRC (#{comment})")
  end
  
  def receive_nick(m)
    nick = m.sender_nick
    tonick = m[0]
    
    if eq(nick, @mynick)
      @mynick = tonick
      update_unit_title
      print_channel(self, :nick, "*You are now known as #{tonick}")
    end
    @channels.each do |c|
      if c.find_member(nick)
        print_channel(c, :nick, "*#{nick} is now known as #{tonick}")
        c.rename_member(nick, tonick)
      end
      if eq(nick, c.name)
        c.name = tonick
        reload_tree
        update_channel_title(c)
      end
    end
    @whois_dialogs.select {|i| i.nick == nick}.each {|i| i.nick = tonick}
    @world.dcc.nick_changed(self, nick, tonick)
    print_console(nil, :nick, "*#{nick} is now known as #{tonick}")
  end
  
  def receive_mode(m)
    nick = m.sender_nick
    target = m[0]
    modestr = m.sequence(1).rstrip
    
    if target.channelname?
      # channel mode
      c = find_channel(target)
      if c
        a = c.mode.a
        c.mode.update(modestr)
        c.clear_members if !a && c.mode.a
        str = modestr.dup
        plus = false
        while !str.empty?
          token = str.token!
          if /^([-+])(.+)$/ =~ token
            plus = ($1 == '+')
            token = $2
            token.each_char do |char|
              case char
              when '-'; plus = false
              when '+'; plus = true
              when 'o'
                t = str.token!
                c.change_member_op(t, :o, plus)
                if t == @mynick
                  c.op = plus
                  update_channel_title(c)
                end
              when 'v'
                t = str.token!
                c.change_member_op(t, :v, plus)
              when 'b','e','I','R'; str.token!
              when 'O','k'; str.token!
              when 'l'; str.token! if plus
              end
            end
          end
        end
        update_channel_title(c)
      end
      print_both(c || target, :mode, "*#{nick} has changed mode: #{modestr}")
    else
      # user mode
      @mymode.update(modestr)
      print_both(self, :mode, "*#{nick} has changed mode: #{modestr}")
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
    print_both(c || chname, :topic, "*#{nick} has set topic: #{topic}")
  end
  
  def receive_invite(m)
    sender = m.sender_nick
    chname = m[1]
    print_both(self, :invite, "*#{sender} has invited you to #{chname}")
  end
  
  def receive_ping(m)
    @pong_timer = PONG_TIME
    send(:pong, ":#{m.sequence}")
  end
  
  def receive_error(m)
    comment = m[0]
    print_error("*Error: #{comment}")
  end
  
  def receive_wallops(m)
    sender = m.sender_nick
    sender = m.sender if !sender || sender.empty?
    comment = m[0]
    print_both(self, :wallops, "*Wallops: #{comment}")
  end
  
  def receive_ctcp_query(m, text)
    text = text.dup
    command = text.token!
    case command.downcase
    when 'action'
      receive_text(m, :action, text)
    when 'dcc'
      kind = text.token!
      case kind.downcase
      when 'send'
        fname = text.token!
        addr = text.token!
        port = text.token!.to_i
        size = text.token!.to_i
        ver = text.token!.to_i
        lfname = text
        if ver >= 2
          lfname[0] = '' if lfname[0] == ?:
          fname = lfname if !lfname.empty?
        end
        receive_dcc_send(m, fname, addr, port, size, ver)
      else
        puts "dcc: #{kind} #{text}"
      end
    else
      puts "ctcp_query: #{command} #{text}"
    end
  end
  
  def receive_dcc_send(m, fname, addr, port, size, ver)
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
    print_both(self, :dcc_send_receive, "*Received file transfer request from #{m.sender_nick}, #{fname} (#{size.grouped_by_comma} bytes) #{host}:#{port}")
    @world.dcc.add_receiver(@id, m.sender_nick, host, port, '~/Desktop', fname, size, ver)
  end
  
  def receive_ctcp_reply(m, text)
    text = text.dup
    command = text.token!
    puts "ctcp_reply: #{command} #{text}"
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
    when 2..5,10,20,42,250..255,265,266,372,375
      print_reply(m)
    when 221  # RPL_UMODEIS
      modestr = m[1].rstrip
      return if modestr == '+'
      @mymode.clear
      @mymode.update(modestr)
      update_unit_title
      print_both(self, :reply, "*Mode: #{modestr}")
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
      signon = signon > 0 ? Time.at(signon).strftime('%Y/%m/%d %H:%M:%S') : ''
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
        a = c.mode.a
        c.mode.clear
        c.mode.update(modestr)
        if c.mode.a && !a
          c.clear_members
        end
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "*Mode: #{modestr}")
    when 329  # hemp? channel creation time
      chname = m[1]
      timestr = m[2]
      time = Time.at(timestr.to_i)
      c = find_channel(chname)
      print_both(c || chname, :reply, "*Created at: #{time.strftime('%Y/%m/%d %H:%M:%S')}")
    when 331  # RPL_NOTOPIC
      chname = m[1]
      c = find_channel(chname)
      if c && c.active?
        c.topic = ''
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "*Topic: ")
    when 332  # RPL_TOPIC
      chname = m[1]
      topic = m[2]
      c = find_channel(chname)
      if c && c.active?
        c.topic = topic
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "*Topic: #{topic}")
    when 333  # RPL_TOPIC_WHO_TIME
      chname = m[1]
      setter = m[2]
      timestr = m[3]
      nick = setter[/^[^!@]+/]
      time = Time.at(timestr.to_i)
      c = find_channel(chname)
      print_both(c || chname, :reply, "*#{nick} set the topic at: #{time.strftime('%Y/%m/%d %H:%M:%S')}")
    when 353  # RPL_NAMREPLY
      chname = m[2]
      trail = m[3].strip
      c = find_channel(chname)
      if c && c.active? && !c.names_init
        trail.split(' ').each do |nick|
          if /^([@+])(.+)/ =~ nick
            op, nick = $1, $2
          end
          m = User.new(nick)
          m.o = op == '@'
          m.v = op == '+'
          c.add_member(m, false)
          c.op = m.o if m.nick == @mynick
        end
        c.reload_members
        c.sort_members
        update_channel_title(c)
      end
      print_both(c || chname, :reply, "*Names: #{trail}")
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
          topic = c.config.topic
          if topic && !topic.empty?
            send(:topic, chname, ":#{topic}")
          end
        end
        update_channel_title(c)
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
when 322	# RPL_LIST
when 323	# RPL_LISTEND
when 341	# RPL_INVITING

when 367	# RPL_BANLIST
when 368	# RPL_ENDOFBANLIST
when 348	# RPL_EXCEPTLIST
when 349	# RPL_ENDOFEXCEPTLIST
when 346	# RPL_INVITELIST
when 347	# RPL_ENDOFINVITELIST
when 344	# RPL_REOPLIST
when 345	# RPL_ENDOFREOPLIST
  
when 352	# RPL_WHOREPLY
when 315	# RPL_ENDOFWHO
when 403	# ERR_NOSUCHCHANNEL 
=end
  
  def receive_error_numeric_reply(m)
    number = m.numeric_reply
    case number
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
if (Status.State == ON) {
when 405	# ERR_TOOMANYCHANNELS
when 471	# ERR_CHANNELISFULL
when 473	# ERR_INVITEONLYCHAN
when 474	# ERR_BANNEDFROMCHAN
when 475	# ERR_BADCHANNELKEY
when 476	# ERR_BADCHANMASK
when 437	# ERR_UNAVAILRESOURCE 2.10
}
=end
  
  def receive_nick_collision(m)
    if @sentnick.length >= IRC::NICKLEN
      if /^(.+)[^_](_*)$/ =~ @sentnick
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
