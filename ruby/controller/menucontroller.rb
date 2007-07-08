# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'uri'
require 'cgi'

class MenuController < OSX::NSObject
  include OSX
  attr_accessor :app, :world, :window, :text, :tree, :pref, :member_list
  
  def initialize
    @server_dialogs = []
    @channel_dialogs = []
  end
  
  def terminate
    @server_dialogs.each {|d| d.close }
    @channel_dialogs.each {|d| d.close }
    @server_dialogs.clear
    @channel_dialogs.clear
  end
  
  objc_method :validateMenuItem, 'c@:@'
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
    
    case i.tag
    when 102  # preferences
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
    when 501  # connect
      not_connected
    when 502  # disconnect
      connected
    when 503  # cancel reconnecting
      !!u && u.reconnecting?
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
      
    when 2001  # member whois
      active_chtalk && count_selected_members?
    when 2002  # member talk
      active_chtalk && count_selected_members?
    when 2003  # member giveop
      op && count_selected_members?
    when 2004  # member deop
      op && count_selected_members?
    when 2011  # dcc send file
      active_chtalk && count_selected_members? && !!u.myaddress      
    else
      false
    end
  end
  
  def count_selected_members?
    @member_list.countSelectedRows > 0
  end
  
  def selected_members
    c = @world.selchannel
    return [] unless c
    @member_list.selectedRows.map {|i| c.members[i.to_i] }
  end
  
  def deselect_members
    @member_list.deselectAll(nil)
  end
  
  def alloc_comment_sheet
    return if @comment
    @comment = CommentSheet.alloc.init
    @comment.window = window
    @comment.delegate = self
    @comment.loadNib
  end
  
  def current_webview
    t = @window.firstResponder
    if t && t.class.name.to_s == 'OSX::WebHTMLView'
      t = t.superview while t && t.class.name.to_s != 'LogView'
      t
    else
      nil
    end
  end
  
  def menuNeedsUpdate(menu)
    menu.update
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
      if sel && !sel.unit? && /.+\r?\n.+/ =~ s
        # multi line
        @paste = PasteSheet.alloc.init
        @paste.window = window
        @paste.delegate = self
        @paste.uid = sel.unit.id
        @paste.cid = sel.id
        @paste.start(s)
      else
        # single line
        @world.select_text if t.class.name.to_s != 'OSX::NSTextView'
        e = win.fieldEditor_forObject(false, @text)
        e.paste(sender)
      end
    else
      if t.respondsToSelector('paste:')
        t.paste(sender) if !t.respondsToSelector('validateMenuItem:') || t.validateMenuItem(sender)
      end
    end
  end
  
  def pasteSheet_onSend(sender, s)
    @paste = nil
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
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
    @world.select_text if t.class.name.to_s != 'OSX::NSTextView'
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
  
  
  def onConnect(sender)
    u = @world.selunit
    return unless u
    u.connect
  end
  
  def onDisconnect(sender)
    u = @world.selunit
    return unless u
    u.disconnect
  end
  
  def onCancelReconnecting(sender)
    u = @world.selunit
    return unless u
    u.cancel_reconnect
  end
  
  
  def onNick(sender)
    u = @world.selunit
    return unless u
    unless @nick
      @nick = NickSheet.alloc.init
      @nick.window = window
      @nick.delegate = self
      @nick.loadNib
    end
    @nick.uid = u.id
    @nick.start(u.mynick)
  end
  
  def nickSheet_onOk(sender, nick)
    u = @world.find_unit_by_id(sender.uid)
    return unless u
    u.change_nick(nick)
  end
  
  def nickSheet_onCancel(sender)
  end
  
  
  def onAddServer(sender)
    u = @world.selunit
    config = u ? u.config.dup : IRCUnitConfig.new
    config.name = ''
    d = ServerDialog.alloc.init
    d.prefix = 'newServerDialog'
    d.delegate = self
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
    d.delegate = self
    u.property_dialog = d
    d.start(u.config, u.id)
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
    alloc_comment_sheet
    @comment.uid = u.id
    @comment.cid = c.id
    @comment.prefix = 'topicPrompt'
    @comment.start('Please input topic.', c.topic)
  end
  
  def topicPrompt_onOk(sender, str)
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
    u.send(:topic, c.name, ":#{str}")
  end
  
  def topicPrompt_onCancel(sender)
  end
  
  
  def onMode(sender)
    u, c = @world.sel
    return unless u && c
    unless @mode
      @mode = ModeSheet.alloc.init
      @mode.window = window
      @mode.delegate = self
      @mode.loadNib
    end
    @mode.uid = u.id
    @mode.cid = c.id
    @mode.start(c.name, c.mode)
  end
  
  def modeSheet_onOk(sender, newmode)
    u, c = @world.find_by_id(sender.uid, sender.cid)
    return unless u && c
    ary = c.mode.get_change_str(newmode)
    ary.each {|i| u.send(:mode, c.name, i) }
  end
  
  def modeSheet_onCancel(sender)
  end
  
  
  def onAddChannel(sender)
    u, c = @world.sel
    return unless u
    config = c ? c.config.dup : IRCChannelConfig.new
    config.name = ''
    d = ChannelDialog.alloc.init
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
  
  
  def whois_selected_members(deselect)
    u = @world.selunit
    return unless u
    selected_members.each {|m| u.send_whois(m.nick) }
    deselect_members if deselect
  end
  
  def memberList_doubleClicked(sender)
    whois_selected_members(false)
  end
  
  def onMemberWhois(sender)
    whois_selected_members(true)
  end
  
  def onMemberTalk(sender)
    u = @world.selunit
    return unless u
    selected_members.each do |m|
      c = u.find_channel(m.nick)
      unless c
        c = @world.create_talk(u, m.nick)
        @world.select(c)
      end
    end
    deselect_members
  end
  
  
  def change_op(mode, plus)
    u, c = @world.sel
    return unless u && u.login? && c && c.active? && c.channel? && c.op?
    members = selected_members.select {|m| m.__send__(mode) != plus }
    members = members.map {|m| m.nick }
    while !members.empty?
      t = members[0..2]
      u.send(:mode, c.name, (plus ? '+' : '-') + mode.to_s * t.length + ' ' + t.join(' '))
      members[0..2] = nil
    end
    deselect_members
  end
  
  def onMemberGiveOp(sender)
    change_op(:o, true)
  end
  
  def onMemberDeop(sender)
    change_op(:o, false)
  end
  
  def onMemberSendFile(sender)
    @send.cancel(nil) if @send
    u = @world.selunit
    return unless u
    @send_targets = selected_members
    return unless @send_targets && !@send_targets.empty?
    @send_uid = u.id
    @send = NSOpenPanel.openPanel
    @send.setCanChooseDirectories(false)
    @send.setResolvesAliases(true)
    @send.setAllowsMultipleSelection(true)
    @send.beginForDirectory_file_types_modelessDelegate_didEndSelector_contextInfo('~/Desktop', nil, nil, self, 'sendFilePanelDidEnd:returnCode:contextInfo:', nil)
  end
  
  objc_method :sendFilePanelDidEnd_returnCode_contextInfo, 'v@:@i^v'
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
end
