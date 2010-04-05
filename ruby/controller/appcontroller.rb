# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'fileutils'
require 'pathname'
require 'preferences'

class AppController < NSObject
  ib_outlet :window, :tree, :logBase, :consoleBase, :memberList, :text, :chatBox
  ib_outlet :tree_scroller, :left_tree_base, :right_tree_base
  ib_outlet :root_split, :log_split, :info_split, :tree_split
  ib_outlet :menu, :serverMenu, :channelMenu, :memberMenu, :treeMenu, :logMenu, :consoleMenu, :urlMenu, :addrMenu, :chanMenu

  KInternetEventClass = KAEGetURL = 1196773964

  def awakeFromNib
    prelude

    # register URL handler
    em = NSAppleEventManager.sharedAppleEventManager
    em.setEventHandler_andSelector_forEventClass_andEventID(self, 'handleURLEvent:withReplyEvent:', KInternetEventClass, KAEGetURL)

    if preferences.general.use_hotkey
      NSApp.registerHotKey_modifierFlags(preferences.general.hotkey_key_code, preferences.general.hotkey_modifier_flags)
    end

    @fieldEditor = FieldEditorTextView.alloc.initWithFrame(NSZeroRect)
    @fieldEditor.setFieldEditor(true)
    @fieldEditor.pasteDelegate = self
    @fieldEditor.setContinuousSpellCheckingEnabled(true)

    @text.setFocusRingType(NSFocusRingTypeNone)
    @window.makeFirstResponder(@text)
    @root_split.setFixedViewIndex(1)
    @log_split.setFixedViewIndex(1)
    @info_split.setFixedViewIndex(1)
    @tree_split.setHidden(true)

    @viewTheme = ViewTheme.alloc.init
    @viewTheme.theme = preferences.theme.name
    @tree.theme = @viewTheme.other
    @memberList.theme = @viewTheme.other
    cell = MemberListViewCell.alloc.init
    cell.setup(@viewTheme.other)
    @memberList.tableColumns[0].setDataCell(cell)

    load_window_state
    @window.alphaValue = preferences.theme.transparency
    select_3column_layout(preferences.general.main_window_layout == Preferences::General::LAYOUT_3_COLUMNS)

    @world = IRCWorld.alloc.init
    @world.app = self
    @world.window = @window
    @world.tree = @tree
    @world.text = @text
    @world.logBase = @logBase
    @world.consoleBase = @consoleBase
    @world.chatBox = @chatBox
    @world.fieldEditor = @fieldEditor
    @world.memberList = @memberList
    @world.serverMenu = @serverMenu
    @world.channelMenu = @channelMenu
    @world.treeMenu = @treeMenu
    @world.logMenu = @logMenu
    @world.consoleMenu = @consoleMenu
    @world.urlMenu = @urlMenu
    @world.addrMenu = @addrMenu
    @world.chanMenu = @chanMenu
    @world.memberMenu = @memberMenu
    @world.menuController = @menu
    @world.viewTheme = @viewTheme
    @world.setup(IRCWorldConfig.alloc.initWithDictionary(NewPreferences.loadWorld))
    @tree.setDataSource(@world)
    @tree.setDelegate(@world)
    @tree.responderDelegate = @world
    @tree.reloadData
    @world.setupTree

    @menu.app = self
    @menu.world = @world
    @menu.window = @window
    @menu.tree = @tree
    @menu.memberList = @memberList
    @menu.text = @text

    @memberList.setTarget(@menu)
    @memberList.setDoubleAction('memberListDoubleClicked:')
    @memberList.keyDelegate = @world
    @memberList.dropDelegate = @world

    @dcc = DccManager.alloc.init
    @dcc.world = @world
    @world.dcc = @dcc

    @history = InputHistory.new

    register_keyHandlers

    nc = NSWorkspace.sharedWorkspace.notificationCenter
    nc.addObserver_selector_name_object(self, :computerWillSleep, NSWorkspaceWillSleepNotification, nil)
    nc.addObserver_selector_name_object(self, :computerDidWake, NSWorkspaceDidWakeNotification, nil)
    
    #@text.setStringValue("#{RUBYCOCOA_VERSION}")
  end

  def computerWillSleep(sender)
    @world.prepare_for_sleep
  end

  def computerDidWake(sender)
    @world.autoConnect(true)
  end

  def terminateWithoutConfirm(sender)
    @terminating = true
    NSApp.terminate(self)
  end

  def applicationDidFinishLaunching(sender)
    #SACrashReporter.submit

    ws = NSWorkspace.sharedWorkspace
    nc = ws.notificationCenter
    nc.addObserver_selector_name_object(self, :terminateWithoutConfirm, NSWorkspaceWillPowerOffNotification, ws)

    start_timer

    #if @world.clients.empty?
    #  # start initial setting
    #  @welcome = WelcomeDialog.alloc.init
    #  @welcome.delegate = self
    #  @welcome.start
    #else
      # show the main window and start auto connecting
      @window.makeKeyAndOrderFront(nil)
      @world.autoConnect
    #end
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
      sel.resetState
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
      if @viewTheme && @viewTheme.other
        dic = @fieldEditor.selectedTextAttributes.mutableCopy
        dic[NSBackgroundColorAttributeName] = @viewTheme.other.input_text_sel_bgcolor
        @fieldEditor.setSelectedTextAttributes(dic)
      end
      @fieldEditor
    else
      nil
    end
  end

  def windowDidBecomeMain(sender)
    @memberList.setNeedsDisplay(true)
  end

  def windowDidResignMain(sender)
    @memberList.setNeedsDisplay(true)
  end

  def windowDidBecomeKey(sender)
    @menu.keyWindowChanged(true)
  end

  def windowDidResignKey(sender)
    @menu.keyWindowChanged(false)
  end

  def fieldEditorTextViewPaste(sender)
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
    u.connect if u.config.autoConnect
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
    @world.preferencesChanged
  end

  def textEntered(sender)
    sendText(:privmsg)
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

  def timerOnTimer(sender)
    @world.onTimer
    @menu.onTimer
  end

  private

  def prelude
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
    FileUtils.cp(Dir.glob(ViewTheme.RESOURCEBASE + '/Sample.*'), newdir.to_s) rescue nil
    
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
      nicks = c.members.sort_by {|i| [-i.weight, i.canonicalNick] }.map {|i| i.nick }
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
      msg << ".\nQuit?"
      NSRunCriticalAlertPanel('LimeChat', msg, 'Quit Anyway', 'Cancel', nil) == NSAlertDefaultReturn
    elsif preferences.general.confirm_quit
      NSRunAlertPanel('LimeChat', 'Quit?', 'Quit', 'Cancel', nil) == NSAlertDefaultReturn
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
        @fieldEditor.setContinuousSpellCheckingEnabled(spell_checking)
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
    win = @window.frame.dictionaryValue
    split = {
      :root => @root_split.position,
      :log => @log_split.position,
      :info => @info_split.position,
      :tree => @tree_split.position,
      :spell_checking => @fieldEditor.isContinuousSpellCheckingEnabled,
    }
    win.merge!(split)
    preferences.save_window('main_window', win)
  end

  # key commands
  
  KEY_RETURN = 0x24
  KEY_TAB = 0x30
  KEY_SPACE = 0x31
  KEY_BACKSPACE = 0x33
  KEY_ESCAPE = 0x35
  KEY_ENTER = 0x4C
  KEY_HOME = 0x73
  KEY_PAGE_UP = 0x74
  KEY_DELETE = 0x75
  KEY_END = 0x77
  KEY_PAGE_DOWN = 0x79
  KEY_LEFT = 0x7B
  KEY_RIGHT = 0x7C
  KEY_DOWN = 0x7D
  KEY_UP = 0x7E

  def handler(sel, key, mods)
    if key.is_a?(Numeric)
      @window.registerKeyHandler_key_modifiers(sel, key, mods)
    else
      @window.registerKeyHandler_character_modifiers(sel, key[0], mods)
    end
  end

  def input_handler(sel, key, mods)
    @fieldEditor.registerKeyHandler_key_modifiers(sel, key, mods)
  end
  
  public
  
  def onHome(e); scroll(:home); end
  def onEnd(e); scroll(:end); end
  def onPageUp(e); scroll(:up); end
  def onPageDown(e); scroll(:down); end
  def onTab(e); tab; end
  def onShiftTab(e); shiftTab; end
  def onCtrlEnter(e); sendText(:notice); end
  def onAltEnter(e); @menu.onPasteDialog(nil); end
  def onCmdClosingBracket(e); move(:down, :active); end
  def onCmdOpeningBracket(e); move(:up, :active); end
  def onCtrlUp(e); move(:up); end
  def onCtrlDown(e); move(:down); end
  def onCtrlLeft(e); move(:left); end
  def onCtrlRight(e); move(:right); end
  def onCmdUp(e); move(:up, :active); end
  def onCmdDown(e); move(:down, :active); end
  def onCmdAltLeft(e); move(:left, :active); end
  def onCmdAltRight(e); move(:right, :active); end
  def onCtrlTab(e); move(:down, :unread); end
  def onCtrlShiftTab(e); move(:up, :unread); end
  def onAltTab(e); @world.select_prev; end
  def onCmdNumber(e); @world.select_channel_at(e.charactersIgnoringModifiers.to_s.to_i); end
  def onCtrlCmdNumber(e); n = e.charactersIgnoringModifiers.to_s.to_i; @world.select_client_at(n == 0 ? 9 : n-1); end
  def onInputUp(e); history_up; end
  def onInputDown(e); history_down; end

  private

  def register_keyHandlers
    @window.setKeyHandlerTarget(self)
    @fieldEditor.setKeyHandlerTarget(self)
    
    handler('onHome:', KEY_HOME, 0)
    handler('onEnd:', KEY_END, 0)
    handler('onPageUp:', KEY_PAGE_UP, 0)
    handler('onPageDown:', KEY_PAGE_DOWN, 0)
    handler('onTab:', KEY_TAB, 0)
    handler('onShiftTab:', KEY_TAB, NSShiftKeyMask)
    handler('onCtrlEnter:', KEY_ENTER, NSControlKeyMask)
    handler('onCtrlEnter:', KEY_RETURN, NSControlKeyMask)
    handler('onAltEnter:', KEY_ENTER, NSAlternateKeyMask)
    handler('onAltEnter:', KEY_RETURN, NSAlternateKeyMask)
    handler('onCmdClosingBracket:', ']', NSCommandKeyMask)
    handler('onCmdOpeningBracket:', '[', NSCommandKeyMask)
    handler('onCtrlUp:', KEY_UP, NSControlKeyMask)
    handler('onCtrlDown:', KEY_DOWN, NSControlKeyMask)
    handler('onCtrlLeft:', KEY_LEFT, NSControlKeyMask)
    handler('onCtrlRight:', KEY_RIGHT, NSControlKeyMask)
    handler('onCmdUp:', KEY_UP, NSCommandKeyMask)
    handler('onCmdUp:', KEY_UP, NSCommandKeyMask|NSAlternateKeyMask)
    handler('onCmdDown:', KEY_DOWN, NSCommandKeyMask)
    handler('onCmdDown:', KEY_DOWN, NSCommandKeyMask|NSAlternateKeyMask)
    handler('onCmdAltLeft:', KEY_LEFT, NSCommandKeyMask|NSAlternateKeyMask)
    handler('onCmdAltRight:', KEY_RIGHT, NSCommandKeyMask|NSAlternateKeyMask)
    handler('onCtrlTab:', KEY_TAB, NSControlKeyMask)
    handler('onCtrlShiftTab:', KEY_TAB, NSControlKeyMask|NSShiftKeyMask)
    handler('onAltTab:', KEY_TAB, NSAlternateKeyMask)
    handler('onCtrlTab:', KEY_SPACE, NSAlternateKeyMask)
    handler('onCtrlShiftTab:', KEY_SPACE, NSAlternateKeyMask|NSShiftKeyMask)
    handler('onCmdNumber:', '0', NSCommandKeyMask)
    handler('onCmdNumber:', '1', NSCommandKeyMask)
    handler('onCmdNumber:', '2', NSCommandKeyMask)
    handler('onCmdNumber:', '3', NSCommandKeyMask)
    handler('onCmdNumber:', '4', NSCommandKeyMask)
    handler('onCmdNumber:', '5', NSCommandKeyMask)
    handler('onCmdNumber:', '6', NSCommandKeyMask)
    handler('onCmdNumber:', '7', NSCommandKeyMask)
    handler('onCmdNumber:', '8', NSCommandKeyMask)
    handler('onCmdNumber:', '9', NSCommandKeyMask)
    handler('onCtrlCmdNumber:', '0', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '1', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '2', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '3', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '4', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '5', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '6', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '7', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '8', NSCommandKeyMask|NSControlKeyMask)
    handler('onCtrlCmdNumber:', '9', NSCommandKeyMask|NSControlKeyMask)
    
    input_handler('onInputUp:', KEY_UP, 0)
    input_handler('onInputUp:', KEY_UP, NSAlternateKeyMask)
    input_handler('onInputDown:', KEY_DOWN, 0)
    input_handler('onInputDown:', KEY_DOWN, NSAlternateKeyMask)
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
