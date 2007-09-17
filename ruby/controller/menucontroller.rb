# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'uri'
require 'cgi'

class MenuController < OSX::NSObject
  include OSX
  attr_accessor :app, :world, :window, :text, :tree, :pref, :member_list
  attr_accessor :url, :addr, :nick
  
  def initialize
    @server_dialogs = []
    @channel_dialogs = []
  end
  
  def terminate
    @server_dialogs.each {|d| d.close }
    @channel_dialogs.each {|d| d.close }
    @server_dialogs.clear
    @channel_dialogs.clear
    @tree_dialog.close if @tree_dialog
    @pref_dialog.close if @pref_dialog
    @autoop_dialog.close if @autoop_dialog
  end
  
  #objc_method :validateMenuItem, 'c@:@'
  def validateMenuItem(i)
    u, c = @world.sel
    
    connected = !!u && u.connected?
    not_connected = !!u && !u.connected?
    login = !!u && u.login?
    active = login && !!c && c.active?
    not_active = login && !!c && !c.active?
    active_channel = active && c.channel?
    active_chtalk = active && (c.channel? || c.talk?)
    op = active_channel && c.op?
    
    tag = i.tag
    tag -= 500 if nick_menu?(i)
    
    case tag
    when 102  # preferences
      true
    when 103  # server tree
      true
    when 104  # auto op
      true
    when 201  # dcc
      true
    when 313  # paste
      return false unless NSPasteboard.generalPasteboard.availableTypeFromArray([NSStringPboardType])
      win = NSApp.keyWindow
      return false unless win
      t = win.firstResponder
      return false unless t
      if win == @window
        return true
      else
        if t.respondsToSelector('paste:')
          return true if !t.respondsToSelector('validateMenuItem:') || t.validateMenuItem(i)
        end
      end
      false
    when 331  # search in google
      t = current_webview
      return false unless t
      t = t.selectedDOMRange
      return false unless t
      sel = t.toString.to_s
      return sel && !sel.empty?
    when 332  # paste my address
      win = NSApp.keyWindow
      return false if !win || win != @window
      t = win.firstResponder
      return false unless t
      u = @world.selunit
      return false unless u && u.myaddress
      true
    
    when 411  # mark scrollback
      true
    when 412  # clear scrollback
      true
      
    when 501  # connect
      not_connected
    when 502  # disconnect
      !!u && (u.connected? || u.connecting?)
    when 503  # cancel reconnecting
      !!u && (u.connecting? || u.reconnecting?)
    when 511  # nick
      login
    when 521  # add server
      true
    when 522  # copy server
      !!u
    when 523  # delete server
      not_connected
    when 541  # server property
      !!u
    when 542  # server auto op
      !!u

    when 601  # join
      login && not_active && c.channel?
    when 602  # leave
      active
    when 611  # mode
      active_channel
    when 612  # topic
      active_channel
    when 651  # add channel
      !!u
    when 652  # delete channel
      !!c
    when 653  # channel property
      !!c && c.channel?
    when 654  # channel auto op
      !!c && c.channel?

    when 802
      true
      
    when 2001  # member whois
      active_chtalk && count_selected_members?(i)
    when 2002  # member talk
      active_chtalk && count_selected_members?(i)
    when 2003  # member giveop
      op && count_selected_members?(i)
    when 2004  # member deop
      op && count_selected_members?(i)
    when 2011  # dcc send file
      active_chtalk && count_selected_members?(i) && !!u.myaddress
    when 2101..2105  # ctcp
      active_chtalk && count_selected_members?(i)
    when 2021  # register to auto op
      active_channel && count_selected_members?(i)
    
    when 3001  # copy url
      true
    when 3101  # copy address
      true
    
    else
      false
    end
  end
  
  def count_selected_members?(sender)
    if nick_menu?(sender)
      !!@nick
    else
      @member_list.countSelectedRows > 0
    end
  end
  
  def selected_members(sender)
    c = @world.selchannel
    return [] unless c
    if nick_menu?(sender)
      m = c.find_member(@nick)
      m ? [m] : []
    else
      @member_list.selectedRows.map {|i| c.members[i.to_i] }
    end
  end
  
  def deselect_members(sender)
    unless nick_menu?(sender)
      @member_list.deselectAll(nil)
    end
  end
  
  def nick_menu?(sender)
    sender && (2500...3000) === sender.tag.to_i
  end
  
  def current_webview
    t = @window.firstResponder
    if t && OSX::WebHTMLView === t
      t = t.superview while t && !(LogView === t)
      t
    else
      nil
    end
  end
  
  def menuNeedsUpdate(menu)
    menu.update
  end
  
  def make_mask(nick, username, address)
    if !nick || nick.empty?
      nick = '*'
    elsif /^(.+)[\d_]+$/ =~ nick
      nick = $1 + '*'
    else
      nick += '*'
    end
    
    if !username || username.empty?
      username = '*'
    else
      if /^([^\d_]+)([\d_]+)$/ =~ username
        username = $1 + '*'
      end
    end
    
    if !address || address.empty?
      address = '*'
    else
      if /^(\d{1,3}\.){3}[\d]{1,3}$/ =~ address || /^([a-f\d]{0,4}:){7}[a-f\d]{0,4}$/ =~ address
        ;
      else
        #if /^[^\.]+\.(.+)$/ =~ address
        #  address = '*.' + $1
        #end
        
        ary = address.split('.')
        if ary.length >= 3
          reserve = ary[-1].length == 2 ? 3 : 2
          left = ary[0...-reserve]
          right = ary[-reserve..-1]
          left = left.map {|i| i.gsub(/\d+/, '*') }
          address = left.join('.') + '.' + right.join('.')
        end
      end
    end
    
    "#{nick}!#{username}@#{address}"
  end
  
  
  def onPreferences(sender)
    unless @pref_dialog
      @pref_dialog = PreferenceDialog.alloc.init
      @pref_dialog.delegate = self
      @pref_dialog.start(@pref)
    else
      @pref_dialog.show
    end
  end
  
  def preferenceDialog_onOk(sender, m)
    @pref.save
    @pref.sync
    @app.preferences_changed
  end
  
  def preferenceDialog_onClose(sender)
    @pref_dialog = nil
  end
  
  def onServerTree(sender)
    unless @tree_dialog
      @tree_dialog = TreeDialog.alloc.init
      @tree_dialog.delegate = self
      @tree_dialog.start(@world.store_tree)
    else
      @tree_dialog.show
    end
  end
  
  def treeDialog_onOk(sender, conf)
    @world.update_order(conf)
  end
  
  def treeDialog_onClose(sender)
    @tree_dialog = nil
  end
  
  def onAutoOp(sender)
    unless @autoop_dialog
      @autoop_dialog = AutoOpDialog.alloc.init
      @autoop_dialog.delegate = self
      @autoop_dialog.start(@world.store_tree)
    else
      @autoop_dialog.show
    end
  end
  
  def autoOpDialog_onOk(sender, conf)
    @world.update_autoop(conf)
  end
  
  def autoOpDialog_onClose(sender)
    @autoop_dialog = nil
  end
  
  
  def onDcc(sender)
    @world.dcc.show
  end
  
  def onPaste(sender)
    return unless NSPasteboard.generalPasteboard.availableTypeFromArray([NSStringPboardType])
    win = NSApp.keyWindow
    return unless win
    t = win.firstResponder
    return unless t
    if win == @window
      s = NSPasteboard.generalPasteboard.stringForType(NSStringPboardType)
      return unless s
      s = s.to_s
      sel = @world.selected
      if sel && !sel.unit? && /(\r\n|\r|\n)[^\r\n]/ =~ s
        # multi line
        start_paste_dialog(sel.unit.id, sel.id, s)
      else
        # single line
        @world.select_text unless OSX::NSTextView === t
        e = win.fieldEditor_forObject(false, @text)
        e.paste(sender)
      end
    else
      if t.respondsToSelector('paste:')
        t.paste(sender) if !t.respondsToSelector('validateMenuItem:') || t.validateMenuItem(sender)
      end
    end
  end
  
  def start_paste_dialog(uid, cid, s)
    @paste = PasteSheet.alloc.init
    @paste.window = window
    @paste.delegate = self
    @paste.uid = uid
    @paste.cid = cid
    @paste.start(s)
  end
  
  def pasteSheet_onSend(sender, s)
    @paste = nil
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
    s = s.gsub(/\r\n|\r|\n/, "\n")
    u.send_text(c, :notice, s)
  end
  
  def pasteSheet_onCancel(sender)
    @paste = nil
  end
  
  def onPasteMyAddress(sender)
    win = NSApp.keyWindow
    return if !win || win != @window
    t = win.firstResponder
    return unless t
    u = @world.selunit
    return unless u && u.myaddress
    @world.select_text unless OSX::NSTextView === t
    e = win.fieldEditor_forObject(false, @text)
    e.replaceCharactersInRange_withString(e.selectedRange, u.myaddress)
    e.scrollRangeToVisible(e.selectedRange)
  end
  
  def onSearchWeb(sender)
    t = current_webview
    return false unless t
    t = t.selectedDOMRange
    return false unless t
    sel = t.toString.to_s
    if sel && !sel.empty?
      sel = CGI.escape(sel)
      url = "http://www.google.com/search?ie=UTF-8&q=#{sel}"
      UrlOpener::openUrl(url)
    end
  end
  
  
  def onMarkScrollback(sender)
    sel = @world.selected
    return unless sel
    sel.log.mark
  end
  
  def onClearScrollback(sender)
    sel = @world.selected
    return unless sel
    sel.log.unmark
  end
  
  
  def onConnect(sender)
    u = @world.selunit
    return unless u
    u.connect
  end
  
  def onDisconnect(sender)
    u = @world.selunit
    return unless u
    u.quit
  end
  
  def onCancelReconnecting(sender)
    u = @world.selunit
    return unless u
    u.cancel_reconnect
  end
  
  
  def onNick(sender)
    u = @world.selunit
    return unless u
    return if @nick
    @nick = NickSheet.alloc.init
    @nick.window = window
    @nick.delegate = self
    @nick.uid = u.id
    @nick.start(u.mynick)
  end
  
  def nickSheet_onOk(sender, nick)
    @nick = nil
    u = @world.find_unit_by_id(sender.uid)
    return unless u
    u.change_nick(nick)
  end
  
  def nickSheet_onCancel(sender)
    @nick = nil
  end
  
  
  def onAddServer(sender)
    u = @world.selunit
    config = u ? u.config.dup : IRCUnitConfig.new
    config.name = ''
    config.channels = []
    d = ServerDialog.alloc.init
    d.parent = @window
    d.delegate = self
    d.prefix = 'newServerDialog'
    @server_dialogs << d
    d.start(config, -1)
  end
  
  def newServerDialog_onClose(sender)
    @server_dialogs.delete(sender)
  end
  
  def newServerDialog_onOk(sender, config)
    @world.create_unit(config)
    @world.save
  end
  
  
  def onCopyServer(sender)
    u = @world.selunit
    return unless u
    config = u.config.dup
    config.channels = []
    config.name += '_' while @world.find_unit(config.name)
    channels = u.channels.select {|c| c.channel? }
    channels.each {|c| config.channels << c.config }
    n = @world.create_unit(config)
    @tree.expandItem(n)
    @world.save
  end
  
  def onDeleteServer(sender)
    u = @world.selunit
    return unless u && !u.connected?
    return unless NSRunAlertPanel('LimeChat', %Q[Do you want to delete "#{u.name}" ?], 'Delete', 'Cancel', nil) == NSAlertDefaultReturn
    @world.destroy_unit(u)
    @world.save
  end
  
  
  def onServerProperties(sender)
    u = @world.selunit
    return unless u
    if u.property_dialog
      u.property_dialog.show
      return
    end
    d = ServerDialog.alloc.init
    d.parent = @window
    d.delegate = self
    u.property_dialog = d
    d.start(u.store_config, u.id)
  end
  
  def serverDialog_onClose(sender)
    u = @world.find_unit_by_id(sender.uid)
    return unless u
    u.property_dialog = nil
  end
  
  def serverDialog_onOk(sender, config)
    u = @world.find_unit_by_id(sender.uid)
    return unless u
    u.update_config(config)
    @world.reload_tree
    @world.save
  end
  
  
  def onServerAutoOp(sender)
    u = @world.selunit
    return unless u
    onAutoOp(sender)
    @autoop_dialog.select_item(u.id)
  end
  
  
  def onJoin(sender)
    u, c = @world.sel
    return unless u && u.login? && c && !c.active? && c.channel?
    u.join_channel(c)
  end
  
  def onLeave(sender)
    u, c = @world.sel
    return unless u && u.login? && c && c.active?
    case c.type
    when :channel; u.part_channel(c)
    when :talk; @world.destroy_channel(c)
    when :dccchat;
    end
  end
  
  
  def onTopic(sender)
    u, c = @world.sel
    return unless u && c
    return if @comment
    @comment = CommentSheet.alloc.init
    @comment.window = window
    @comment.delegate = self
    @comment.uid = u.id
    @comment.cid = c.id
    @comment.prefix = 'topicPrompt'
    @comment.start('Please input topic.', c.topic)
  end
  
  def topicPrompt_onOk(sender, str)
    @comment = nil
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
    u.send(:topic, c.name, ":#{str}")
  end
  
  def topicPrompt_onCancel(sender)
    @comment = nil
  end
  
  
  def onMode(sender)
    u, c = @world.sel
    return unless u && c
    return if @mode
    @mode = ModeSheet.alloc.init
    @mode.window = window
    @mode.delegate = self
    @mode.uid = u.id
    @mode.cid = c.id
    @mode.start(c.name, c.mode)
  end
  
  def modeSheet_onOk(sender, newmode)
    @mode = nil
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
    ary = c.mode.get_change_str(newmode)
    ary.each {|i| u.send(:mode, c.name, i) }
  end
  
  def modeSheet_onCancel(sender)
    @mode = nil
  end
  
  
  def onAddChannel(sender)
    u, c = @world.sel
    return unless u
    config = c && c.channel? ? c.config.dup : IRCChannelConfig.new
    config.name = ''
    d = ChannelDialog.alloc.init
    d.parent = @window
    d.delegate = self
    d.prefix = 'newChannelDialog'
    @channel_dialogs << d
    d.start(config, u.id, -1)
  end
  
  def newChannelDialog_onClose(sender)
    @channel_dialogs.delete(sender)
  end
  
  def newChannelDialog_onOk(sender, config)
    u = @world.find_unit_by_id(sender.uid)
    return unless u
    @world.create_channel(u, config)
    @world.save
    @world.expand_unit(u)
  end
  
  
  def onDeleteChannel(sender)
    #return unless NSRunAlertPanel('LimeChat', 'Do you want to delete the channel?', 'Delete', 'Cancel', nil) == NSAlertDefaultReturn
    c = @world.selchannel
    return unless c
    @world.destroy_channel(c)
    @world.save
  end
  
  
  def onChannelProperties(sender)
    u, c = @world.sel
    return unless u && c
    if c.property_dialog
      c.property_dialog.show
      return
    end
    d = ChannelDialog.alloc.init
    d.parent = @window
    d.delegate = self
    c.property_dialog = d
    d.start(c.config, u.id, c.id)
  end
  
  def channelDialog_onClose(sender)
    c = @world.find_channel_by_id(sender.uid, sender.cid)
    return unless c
    c.property_dialog = nil
  end
  
  def channelDialog_onOk(sender, config)
    c = @world.find_channel_by_id(sender.uid, sender.cid)
    return unless c
    c.update_config(config)
    @world.save
  end
  
  
  def onChannelAutoOp(sender)
    u, c = @world.sel
    return unless u && c
    onAutoOp(sender)
    @autoop_dialog.select_item(u.id, c.name)
  end
  
  
  def changeStyle(sender)
    style = <<-EOM
      html {
        margin: 0;
        padding: 0;
      }
      body {
        font-family: 'Osaka-Mono';
        font-size: 14pt;
        word-wrap: break-word;
        margin: 3px 4px 10px 4px;
        padding: 0;
      }
      img { border: 1px solid #aaa; vertical-align: top; }
      object { vertical-align: top; }
      .url {}
      .address { text-decoration: underline; }
      .highlight { color: #f0f; font-weight: bold; }
      .line { margin: 2px 0; }
      .time { color: #048; }
      .place { color: #008; }
      .nick_normal { color: #008; }
      .nick_myself { color: #66a; }
      .system { color: #080; }
      .error { color: #f00; font-weight: bold; }
      .reply { color: #088; }
      .error_reply { color: #f00; }
      .dcc_send_send { color: #088; }
      .dcc_send_receive { color: #00c; }
      .privmsg { color: #000; }
      .notice { color: #888; }
      .action { color: #080; }
      .join { color: #080; }
      .part { color: #080; }
      .kick { color: #080; }
      .quit { color: #080; }
      .kill { color: #080; }
      .nick { color: #080; }
      .mode { color: #080; }
      .topic { color: #080; }
      .invite { color: #080; }
      .wallops { color: #080; }
      .debug_send { color: #880; }
      .debug_receive { color: #444; }
    EOM
    @world.change_log_style(style);
  end
  
  
  def whois_selected_members(sender, deselect)
    u = @world.selunit
    return unless u
    selected_members(sender).each {|m| u.send_whois(m.nick) }
    deselect_members(sender) if deselect
  end
  
  def memberList_doubleClicked(sender)
    whois_selected_members(nil, false)
  end
  
  def onMemberWhois(sender)
    whois_selected_members(sender, true)
  end
  
  def onMemberTalk(sender)
    u = @world.selunit
    return unless u
    selected_members(sender).each do |m|
      c = u.find_channel(m.nick)
      unless c
        c = @world.create_talk(u, m.nick)
        @world.select(c)
      end
    end
    deselect_members(sender)
  end
  
  
  def change_op(sender, mode, plus)
    u, c = @world.sel
    return unless u && u.login? && c && c.active? && c.channel? && c.op?
    u.change_op(c, selected_members(sender), mode, plus)
    deselect_members(sender)
  end
  
  def onMemberGiveOp(sender)
    change_op(sender, :o, true)
  end
  
  def onMemberDeop(sender)
    change_op(sender, :o, false)
  end
  
  def onMemberSendFile(sender)
    @send.cancel(nil) if @send
    u = @world.selunit
    return unless u
    @send_targets = selected_members(sender)
    return unless @send_targets && !@send_targets.empty?
    @send_uid = u.id
    @send = NSOpenPanel.openPanel
    @send.setCanChooseDirectories(false)
    @send.setResolvesAliases(true)
    @send.setAllowsMultipleSelection(true)
    @send.beginForDirectory_file_types_modelessDelegate_didEndSelector_contextInfo('~/Desktop', nil, nil, self, 'sendFilePanelDidEnd:returnCode:contextInfo:', nil)
  end
  
  #objc_method :sendFilePanelDidEnd_returnCode_contextInfo, 'v@:@i^v'
  def sendFilePanelDidEnd_returnCode_contextInfo(panel, code, info)
    targets = @send_targets
    uid = @send_uid
    @send_targets = nil
    @send_uid = nil
    @send = nil
    return if code != NSOKButton
    files = panel.filenames.to_a
    files = files.map {|i| i.to_s}
    targets.each do |t|
      files.each {|f| @world.dcc.add_sender(uid, t.nick, f) }
    end
  end
  
  def send_ctcp_query(sender, cmd, param=nil)
    u = @world.selunit
    return unless u && u.login?
    selected_members(sender).each do |m|
      u.send_ctcp_query(m.nick, cmd, param)
    end
    deselect_members(sender)
  end
  
  def onMemberPing(sender)
    n = Time.now
    i = n.to_i * 1000000 + n.usec
    send_ctcp_query(sender, :ping, i.to_s)
  end
  
  def onMemberTime(sender)
    send_ctcp_query(sender, :time)
  end
  
  def onMemberVersion(sender)
    send_ctcp_query(sender, :version)
  end
  
  def onMemberUserInfo(sender)
    send_ctcp_query(sender, :userinfo)
  end
  
  def onMemberClientInfo(sender)
    send_ctcp_query(sender, :clientinfo)
  end
  
  def onMemberAutoOp(sender)
    u = @world.selunit
    return unless u && u.login?
    members = selected_members(sender)
    return if members.empty?
    onChannelAutoOp(sender)
    return unless @autoop_dialog
    if members.length == 1
      m = members[0]
      @autoop_dialog.set_mask(make_mask(m.nick, m.username, m.address))
    else
      ary = members.map {|m| make_mask(m.nick, m.username, m.address) }
      @autoop_dialog.add_masks(ary)
    end
  end
  
  
  def onCopyUrl(sender)
    return unless @url
    pb = NSPasteboard.generalPasteboard
    pb.declareTypes_owner([NSStringPboardType], self)
    pb.setString_forType(@url, NSStringPboardType)
    @url = nil
  end
  
  def onCopyAddress(sender)
    return unless @addr
    pb = NSPasteboard.generalPasteboard
    pb.declareTypes_owner([NSStringPboardType], self)
    pb.setString_forType(@addr, NSStringPboardType)
    @addr = nil
  end
end
