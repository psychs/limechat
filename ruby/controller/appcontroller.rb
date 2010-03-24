# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'fileutils'
require 'pathname'
require 'preferences'

class AppController < NSObject
  ib_outlet :window, :tree, :log_base, :console_base, :member_list, :text, :chat_box
  ib_outlet :tree_scroller, :left_tree_base, :right_tree_base
  ib_outlet :root_split, :log_split, :info_split, :tree_split
  ib_outlet :menu, :server_menu, :channel_menu, :member_menu, :tree_menu, :log_menu, :console_menu, :url_menu, :addr_menu, :chan_menu

  KInternetEventClass = KAEGetURL = 1196773964

  def awakeFromNib
    prelude

    # register URL handler
    em = NSAppleEventManager.sharedAppleEventManager
    em.setEventHandler_andSelector_forEventClass_andEventID(self, 'handleURLEvent:withReplyEvent:', KInternetEventClass, KAEGetURL)

    if preferences.general.use_hotkey
      NSApp.registerHotKey_modifierFlags(preferences.general.hotkey_key_code, preferences.general.hotkey_modifier_flags)
    end

    @field_editor = FieldEditorTextView.alloc.initWithFrame(NSZeroRect)
    @field_editor.setFieldEditor(true)
    @field_editor.paste_delegate = self
    @field_editor.setContinuousSpellCheckingEnabled(true)

    @text.setFocusRingType(NSFocusRingTypeNone)
    @window.makeFirstResponder(@text)
    @root_split.setFixedViewIndex(1)
    @log_split.setFixedViewIndex(1)
    @info_split.setFixedViewIndex(1)
    @tree_split.setHidden(true)

    @view_theme = ViewTheme.new(preferences.theme.name)
    @tree.theme = @view_theme.other
    @member_list.theme = @view_theme.other
    cell = MemberListViewCell.alloc.init
    cell.setup(@view_theme.other)
    @member_list.tableColumns[0].setDataCell(cell)

    load_window_state
    @window.alphaValue = preferences.theme.transparency
    select_3column_layout(preferences.general.main_window_layout == Preferences::General::LAYOUT_3_COLUMNS)

    @world = IRCWorld.alloc.init
    @world.app = self
    @world.window = @window
    @world.tree = @tree
    @world.text = @text
    @world.log_base = @log_base
    @world.console_base = @console_base
    @world.chat_box = @chat_box
    @world.field_editor = @field_editor
    @world.member_list = @member_list
    @world.server_menu = @server_menu
    @world.channel_menu = @channel_menu
    @world.tree_menu = @tree_menu
    @world.log_menu = @log_menu
    @world.console_menu = @console_menu
    @world.url_menu = @url_menu
    @world.addr_menu = @addr_menu
    @world.chan_menu = @chan_menu
    @world.member_menu = @member_menu
    @world.menu_controller = @menu
    @world.view_theme = @view_theme
    @world.setup(IRCWorldConfig.new(preferences.load_world))
    @tree.setDataSource(@world)
    @tree.setDelegate(@world)
    @tree.responder_delegate = @world
    @tree.reloadData
    @world.setup_tree

    @menu.app = self
    @menu.world = @world
    @menu.window = @window
    @menu.tree = @tree
    @menu.member_list = @member_list
    @menu.text = @text

    @member_list.setTarget(@menu)
    @member_list.setDoubleAction('memberList_doubleClicked:')
    @member_list.key_delegate = @world
    @member_list.drop_delegate = @world

    @dcc = DccManager.alloc.init
    @dcc.world = @world
    @world.dcc = @dcc

    @history = InputHistory.new
    @gc_count = 0

    register_key_handlers

    nc = NSWorkspace.sharedWorkspace.notificationCenter
    nc.addObserver_selector_name_object(self, :computerWillSleep, NSWorkspaceWillSleepNotification, nil)
    nc.addObserver_selector_name_object(self, :computerDidWake, NSWorkspaceDidWakeNotification, nil)
    
    #@text.setStringValue("#{RUBYCOCOA_VERSION}")
  end

  def computerWillSleep(sender)
    @world.prepare_for_sleep
  end

  def computerDidWake(sender)
    @world.auto_connect(true)
  end

  def terminateWithoutConfirm(sender)
    @terminating = true
    NSApp.terminate(self)
  end

  def applicationDidFinishLaunching(sender)
    SACrashReporter.submit

    ws = NSWorkspace.sharedWorkspace
    nc = ws.notificationCenter
    nc.addObserver_selector_name_object(self, :terminateWithoutConfirm, NSWorkspaceWillPowerOffNotification, ws)

    start_timer

    if @world.clients.empty?
      # start initial setting
      @welcome = WelcomeDialog.alloc.init
      @welcome.delegate = self
      @welcome.start
    else
      # show the main window and start auto connecting
      @window.makeKeyAndOrderFront(nil)
      @world.auto_connect
    end
  end

  def applicationShouldTerminate(sender)
    return NSTerminateNow if @terminating
    if queryTerminate
      NSTerminateNow
    else
      NSTerminateCancel
    end
  end

  def applicationWillTerminate(notification)
    # unregister URL handler
    em = NSAppleEventManager.sharedAppleEventManager
    em.removeEventHandlerForEventClass_andEventID(KInternetEventClass, KAEGetURL)

    NSApp.unregisterHotKey
    stop_timer
    @menu.terminate
    @world.terminate
    @dcc.save_window_state
    save_window_state
    #@world.save
  end

  def applicationDidBecomeActive(notification)
    sel = @world.selected
    if sel
      sel.reset_state
      @world.update_icon
    end
    @tree.setNeedsDisplay(true)
  end

  def applicationDidResignActive(notification)
    @tree.setNeedsDisplay(true)
  end

  def applicationDidReceiveHotKey(sender)
    if !@window.isVisible || !NSApp.isActive
      NSApp.activateIgnoringOtherApps(true)
      @window.makeKeyAndOrderFront(nil)
      @world.select_text
    else
      NSApp.hide(nil)
    end
  end

  def handleURLEvent_withReplyEvent(event, replyEvent)
    url = event.descriptorAtIndex(1).stringValue.to_s
  end

  def windowShouldClose(sender)
    if queryTerminate
      @terminating = true
      true
    else
      false
    end
  end

  def windowWillClose(notification)
    terminateWithoutConfirm(self)
  end

  def windowWillReturnFieldEditor_toObject(sender, obj)
    if obj == @text
      if @view_theme && @view_theme.other
        dic = @field_editor.selectedTextAttributes.mutableCopy
        dic[NSBackgroundColorAttributeName] = @view_theme.other.input_text_sel_bgcolor
        @field_editor.setSelectedTextAttributes(dic)
      end
      @field_editor
    else
      nil
    end
  end

  def windowDidBecomeMain(sender)
    @member_list.setNeedsDisplay(true)
  end

  def windowDidResignMain(sender)
    @member_list.setNeedsDisplay(true)
  end

  def windowDidBecomeKey(sender)
    @menu.keyWindowChanged(true)
  end

  def windowDidResignKey(sender)
    @menu.keyWindowChanged(false)
  end

  def fieldEditorTextView_paste(sender)
    s = NSPasteboard.generalPasteboard.stringForType(NSStringPboardType)
    return false unless s
    s = s.to_s
    sel = @world.selected
    if sel && !sel.client? && /(\r\n|\r|\n)[^\r\n]/ =~ s
      @menu.start_paste_dialog(sel.client.mynick, sel.client.uid, sel.uid, s)
      true
    else
      false
    end
  end

  UTF8_NETS = %w|freenode undernet quakenet mozilla ustream|

  def welcomeDialog_onOk(sender, c)
    host = c[:host]
    if host =~ /^[^\s]+\s+\(([^()]+)\)/
      c[:name] = $1
    else
      c[:name] = host
    end
    nick = c[:nick]
    c[:username] = nick.downcase.gsub(/[^a-zA-Z\d]/, '_')
    c[:realname] = nick
    c[:channels].map! {|i| { :name => i } }
    if LanguageSupport.primary_language == 'ja'
      net = host.downcase
      if UTF8_NETS.any? {|i| net.include?(i)}
        c[:encoding] = NSUTF8StringEncoding
      end
    end
    u = @world.create_client(IRCClientConfig.new(c))
    @world.save
    u.connect if u.config.auto_connect
  end

  def welcomeDialog_onClose(sender)
    @welcome = nil
    @window.makeKeyAndOrderFront(nil)
  end

  def select_3column_layout(value)
    return if @info_split.hidden? == !!value
    if value
      @info_split.setHidden(true)
      @info_split.setInverted(true)
      @left_tree_base.addSubview(@tree_scroller)
      @tree_split.setHidden(false)
      @tree_split.setPosition(120.0) if @tree_split.position < 1.0
      f = @left_tree_base.frame
      @tree_scroller.setFrame(NSRect.new(0,0,f.width,f.height))
    else
      @tree_split.setHidden(true)
      @right_tree_base.addSubview(@tree_scroller)
      @info_split.setInverted(false)
      @info_split.setHidden(false)
      @info_split.setPosition(100.0) if @info_split.position < 1.0
      f = @right_tree_base.frame
      @tree_scroller.setFrame(NSRect.new(0,0,f.width,f.height))
    end
  end

  def update_layout
    @window.alphaValue = preferences.theme.transparency
    select_3column_layout(preferences.general.main_window_layout == Preferences::General::LAYOUT_3_COLUMNS)
    @world.preferences_changed
  end

  def textEntered(sender)
    sendText(:privmsg)
    @gc_count = 0
  end

  def sendText(cmd)
    s = @text.stringValue.to_s
    unless s.empty?
      if @world.input_text(s, cmd)
        @history.add(s)
        @text.setStringValue('')
      end
    end
    @world.select_text
    @comletion_status.clear if @comletion_status
  end

  def addToHistory
    s = @text.stringValue.to_s
    unless s.empty?
      @history.add(s)
      @text.setStringValue('')
    end
  end

  # timer

  def start_timer
    stop_timer if @timer
    @timer = Timer.alloc.init
    @timer.start(1.0)
    @timer.delegate = self
  end

  def stop_timer
    @timer.stop
    @timer = nil
  end

  GC_TIME = 600

  def timer_onTimer(sender)
    @world.on_timer
    @menu.on_timer
    @gc_count += 1
    if @gc_count >= GC_TIME
      #GC.start
      @gc_count = 0
    end
  end

  private

  def prelude
    # migrate Theme to Themes
    olddir = Pathname.new('~/Library/LimeChat/Theme').expand_path
    newdir = Pathname.new('~/Library/LimeChat/Themes').expand_path
    if olddir.directory? && !newdir.exist?
      FileUtils.mv(olddir.to_s, newdir.to_s) rescue nil
    end

    # migrate ~/Library to ~/Library/Application Support
    olddir = Pathname.new('~/Library/LimeChat/Themes').expand_path
    newdir = Pathname.new('~/Library/Application Support/LimeChat/Themes').expand_path
    if olddir.directory? && !newdir.exist?
      FileUtils.mkpath(Pathname.new('~/Library/Application Support/LimeChat').expand_path.to_s) rescue nil
      FileUtils.mv(olddir.to_s, newdir.to_s) rescue nil
    end

    # migrate NSUserDefaults keys
    # For now add both the nested hashes and all the key-value pairs in the root
    # with a key which indicates in which section they belong.
    defaults = NSUserDefaults.standardUserDefaults
    if pref = defaults[:pref]
      new_pref = pref.to_ruby.inject({}) do |hash, (key, value)|
        new_key = case key
        when :gen then :General
        when :key then :Keyword
        else
          key.to_s.capitalize.to_sym
        end
        hash[new_key] = value
        hash
      end
      #defaults[:Preferences] = new_pref
      defaults.removeObjectForKey(:pref)
      
      new_pref.each do |section, values|
        values.each do |key, value|
          defaults["Preferences.#{section}.#{key}"] = value
        end
      end
      
      # migrate DCC address detection method tag values.
      # Because we can use bindings if the tag which returns 0 is the one where the text field should be enabled.
      if preferences.dcc.address_detection_method == 0
        preferences.dcc.address_detection_method = 2
      elsif preferences.dcc.address_detection_method == 2
        preferences.dcc.address_detection_method = 0
      end
      
      defaults.removeObjectForKey(:pref)
      defaults.synchronize
    end
    
    # migrate dcc.auto_receive
    if defaults['Preferences.Dcc.auto_receive']
      preferences.dcc.action = Preferences::Dcc::ACTION_AUTO_ACCEPT
      defaults.removeObjectForKey('Preferences.Dcc.auto_receive')
      defaults.synchronize
    end
    
    # migrate paste syntax
    case preferences.general.paste_syntax
    when 'privmsg','notice'
      preferences.general.paste_syntax = 'plain_text'
    end
    
    # initialize theme directory
    FileUtils.mkpath(Pathname.new('~/Library/Application Support/LimeChat/Themes').expand_path.to_s) rescue nil
    FileUtils.cp(Dir.glob(ViewTheme.RESOURCE_BASE + '/Sample.*'), newdir.to_s) rescue nil
    
    # migrate ADDR_DETECT_NIC to ADDR_DETECT_JOIN
    if preferences.dcc.address_detection_method == Preferences::Dcc::ADDR_DETECT_NIC
      preferences.dcc.address_detection_method = Preferences::Dcc::ADDR_DETECT_JOIN
    end
  end

  class NickCompletionStatus
    attr_reader :text, :range

    def clear
      @text = @range = nil
    end

    def store(text, range)
      @text = text
      @range = range
    end
  end

  def complete_nick(forward)
    u, c = @world.sel
    return unless u && c
    @world.select_text if @window.firstResponder != @window.fieldEditor_forObject(true, @text)
    fe = @window.fieldEditor_forObject(true, @text)
    return unless fe
    r = fe.selectedRanges.to_a[0]
    return unless r
    r = r.rangeValue

    @comletion_status ||= NickCompletionStatus.new
    status = @comletion_status
    if status.text == @text.stringValue.to_s && status.range && status.range.max == r.location && r.length == 0
      r = status.range.dup
    end

    # pre is the left part of the cursor
    # sel is the right part of the cursor

    s = @text.stringValue
    pre = s.substringToIndex(r.location).to_s
    sel = s.substringWithRange(r).to_s
    if /[\s~!#\$%&*()<>=+'";:,.?]([^\s]*)$/ =~ pre
      pre = $1
      head = false
    else
      head = true
    end
    return if pre.empty?

    # workaround for the @nick form
    # @nick should not be @nick:

    command_mode = false
    headchar = pre[0]
    if head && /^\// =~ pre
      pre[0] = ''
      command_mode = true
    elsif /^[^\w\[\]\\`_^{}|]/ =~ pre
      head = true if head && headchar == ?@
      pre[0] = ''
      return if pre.empty?
    end

    # prepare for the matching

    current = pre + sel
    current = $1 if /([^:\s]+):?\s?$/ =~ current
    downpre = pre.downcase
    downcur = current.downcase

    # sort the choices

    if command_mode
      nicks = %w|action away ban clear ctcp ctcpreply cycle dehalfop deop devoice halfop hop
                  invite j join kick kill leave list mode msg nick notice op part ping
                  privmsg query quit quote raw rejoin t timer topic unban voice weights
                  who whois|
      nicks = nicks.select {|i| i[0...pre.size] == downpre }
    else
      nicks = c.members.sort_by {|i| [-i.weight, i.canonical_nick] }.map {|i| i.nick }
      nicks = nicks.select {|i| i[0...pre.size].downcase == downpre }
      nicks -= [u.mynick]
    end
    return if nicks.empty?

    # find the next choice

    index = nicks.index {|i| i.downcase == downcur }
    if index
      if forward
        index += 1
        index = 0 if nicks.size <= index
      else
        index -= 1
        index = nicks.size - 1 if index < 0
      end
      s = nicks[index]
    else
      s = nicks[0]
    end

    # add suffix

    if command_mode
      s += ' '
    else
      if head
        if headchar == ?@
          s += ' '
        else
          s += ': '
        end
      end
    end

    # set completed nick to the text field

    ps = pre.to_ns
    ns = s.to_ns
    range = r.dup
    range.location -= ps.length
    range.length += ps.length
    fe.replaceCharactersInRange_withString(range, ns)
    fe.scrollRangeToVisible(fe.selectedRange)
    range.location += ns.length
    range.length = 0
    fe.setSelectedRange(range)

    if nicks.size == 1
      status.clear
    else
      r.length = ns.length - ps.length
      status.store(@text.stringValue.to_s, r)
    end
  rescue
    p $!
  end

  def queryTerminate
    rec = @dcc.count_receiving_items
    send = @dcc.count_sending_items
    if rec > 0 || send > 0
      msg = "Now you are "
      if rec > 0
        msg << "receiving #{rec} files"
      end
      if send > 0
        msg << " and " if rec > 0
        msg << "sending #{send} files"
      end
      msg << ".\nAre you sure you want to quit?"
      NSRunCriticalAlertPanel('LimeChat', msg, 'Quit Anyway', 'Cancel', nil) == NSAlertDefaultReturn
    elsif preferences.general.confirm_quit
      NSRunAlertPanel('LimeChat', 'Are you sure you want to quit?', 'Quit', 'Cancel', nil) == NSAlertDefaultReturn
    else
      true
    end
  end

  def load_window_state
    if win = preferences.load_window('main_window')
      f = NSRect.from_dic(win)
      
      @window.setFrame_display(f, true)
      @root_split.setPosition(win[:root])
      @log_split.setPosition(win[:log])
      @info_split.setPosition(win[:info])
      @tree_split.setPosition(win[:tree] || 120)
      
      spell_checking = win[:spell_checking]
      if spell_checking != nil
        @field_editor.setContinuousSpellCheckingEnabled(spell_checking)
      end
    else
      scr = NSScreen.screens[0]
      if scr
        p = scr.visibleFrame.center
        w = 500
        h = 500
        win = {
          :x => p.x - w/2,
          :y => p.y - h/2,
          :w => w,
          :h => h
        }
        f = NSRect.from_dic(win)
        @window.setFrame_display(f, true)
      end
      @root_split.setPosition(150)
      @log_split.setPosition(150)
      @info_split.setPosition(250)
      @tree_split.setPosition(120)
    end
  end

  def save_window_state
    win = @window.frame.to_dic
    split = {
      :root => @root_split.position,
      :log => @log_split.position,
      :info => @info_split.position,
      :tree => @tree_split.position,
      :spell_checking => @field_editor.isContinuousSpellCheckingEnabled,
    }
    win.merge!(split)
    preferences.save_window('main_window', win)
  end

  # key commands

  def handler(*args, &block)
    @window.register_key_handler(*args, &block)
  end

  def input_handler(*args, &block)
    @field_editor.register_key_handler(*args, &block)
  end

  def register_key_handlers
    handler(:home) { scroll(:home) }
    handler(:end) { scroll(:end) }
    handler(:pageup) { scroll(:up) }
    handler(:pagedown) { scroll(:down) }
    handler(:tab) { tab }
    handler(:tab, :shift) { shiftTab }
    handler(:enter, :ctrl) { sendText(:notice); true }
    handler(:enter, :alt) { @menu.onPasteDialog(nil); true }
    handler(:']', :cmd) { move(:down, :active); true }
    handler(:'[', :cmd) { move(:up, :active); true }
    handler(:up, :ctrl) { move(:up); true }
    handler(:down, :ctrl) { move(:down); true }
    handler(:left, :ctrl) { move(:left); true }
    handler(:right, :ctrl) { move(:right); true }
    handler(:up, :cmd) { move(:up, :active); true }
    handler(:down, :cmd) { move(:down, :active); true }
    handler(:up, :cmd, :alt) { move(:up, :active); true }
    handler(:down, :cmd, :alt) { move(:down, :active); true }
    handler(:left, :cmd, :alt) { move(:left, :active); true }
    handler(:right, :cmd, :alt) { move(:right, :active); true }
    handler(:tab, :ctrl) { move(:down, :unread); true }
    handler(:tab, :ctrl, :shift) { move(:up, :unread); true }
    handler(:tab, :alt) { @world.select_prev; true }
    handler(:space, :alt) { move(:down, :unread); true }
    handler(:space, :alt, :shift) { move(:up, :unread); true }
    handler('0'..'9', :cmd) {|n| @world.select_channel_at(n.to_s.to_i); true }
    handler('0'..'9', :cmd, :ctrl) {|n| n = n.to_s.to_i; @world.select_client_at(n == 0 ? 9 : n-1); true }

    input_handler(:up) { history_up; true }
    input_handler(:up, :alt) { history_up; true }
    input_handler(:down) { history_down; true }
    input_handler(:down, :alt) { history_down; true }
  end

  def history_up
    s = @history.up(@text.stringValue.to_s)
    if s
      @text.setStringValue(s)
      @world.select_text
    end
  end

  def history_down
    s = @history.down(@text.stringValue.to_s)
    if s
      @text.setStringValue(s)
      @world.select_text
    end
  end

  def scroll(direction)
    if @window.firstResponder == @text.currentEditor
      sel = @world.selected
      if sel
        log = sel.log
        view = log.view
        case direction
        when :up; view.scrollPageUp(self)
        when :down; view.scrollPageDown(self)
        when :home; log.moveToTop
        when :end; log.moveToBottom
        end
      end
      true
    else
      false
    end
  end

  def tab
    case preferences.general.tab_action
    when Preferences::General::TAB_UNREAD
      move(:down, :unread)
      true
    when Preferences::General::TAB_COMPLETE_NICK
      complete_nick(true)
      true
    else
      false
    end
  end

  def shiftTab
    case preferences.general.tab_action
    when Preferences::General::TAB_UNREAD
      move(:up, :unread)
      true
    when Preferences::General::TAB_COMPLETE_NICK
      complete_nick(false)
      true
    else
      false
    end
  end

  def move(direction, target=:all)
    case direction
    when :up,:down
      sel = @world.selected
      return false unless sel
      n = @tree.rowForItem(sel)
      return false unless n
      n = n.to_i
      start = n
      size = @tree.numberOfRows.to_i
      loop do
        if direction == :up
          n -= 1
          n = size - 1 if n < 0
        else
          n += 1
          n = 0 if n >= size
        end
        break if n == start
        i = @tree.itemAtRow(n)
        if i
          case target
          when :active
            if !i.client? && i.active?
              @world.select(i)
              break
            end
          when :unread
            if i.unread
              @world.select(i)
              break
            end
          else
            @world.select(i)
            break
          end
        end
      end
      true
    when :left,:right
      sel = @world.selected
      return false unless sel
      client = sel.client
      n = @world.clients.index(client)
      return false unless n
      start = n
      size = @world.clients.size
      loop do
        if direction == :left
          n -= 1
          n = size - 1 if n < 0
        else
          n += 1
          n = 0 if n >= size
        end
        client = @world.clients[n]
        if client
          case target
          when :active
            if client.login?
              t = client.last_selected_channel
              t = client unless t
              @world.select(t)
              break
            end
          else
            t = client.last_selected_channel
            t = client unless t
            @world.select(t)
            break
          end
        end
      end
      true
    end
  end
end
