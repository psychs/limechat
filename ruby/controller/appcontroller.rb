# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class AppController < OSX::NSObject
  include OSX
  ib_outlet :window, :tree, :log_base, :console_base, :member_list, :text
  ib_outlet :root_split, :log_split, :info_split
  ib_outlet :menu, :server_menu, :channel_menu, :member_menu, :tree_menu, :log_menu, :console_menu
  
  def awakeFromNib
    app = NSApplication.sharedApplication
    nc = NSWorkspace.sharedWorkspace.notificationCenter
    nc.addObserver_selector_name_object(self, :terminateWithoutConfirm, NSWorkspaceWillPowerOffNotification, NSWorkspace.sharedWorkspace)
    
    @pref = Preferences.new
    @pref.load
    
    @window.key_delegate = self
    @text.setFocusRingType(NSFocusRingTypeNone)
    @window.makeFirstResponder(@text)
    @root_split.setFixedViewIndex(1)
    @log_split.setFixedViewIndex(1)
    @info_split.setFixedViewIndex(1)
    load_window_state
    
    @world = IRCWorld.alloc.init
    @world.pref = @pref
    @world.window = @window
    @world.tree = @tree
    @world.text = @text
    @world.log_base = @log_base
    @world.console_base = @console_base
    @world.member_list = @member_list
    @world.server_menu = @server_menu
    @world.channel_menu = @channel_menu
    @world.tree_menu = @tree_menu
    @world.log_menu = @log_menu
    @world.console_menu = @console_menu
    @tree.setDataSource(@world)
    @tree.setDelegate(@world)
    @tree.responder_delegate = @world
    #cell = UnitNameCell.alloc.init
    #cell.view = @tree
    #@tree.tableColumnWithIdentifier('name').setDataCell(cell)
    #@tree.setIndentationPerLevel(0.0)
    #seed = {:units => {}}
    #@world.setup(IRCWorldConfig.new(seed))
    @world.setup(IRCWorldConfig.new(@pref.load_world))
    @tree.reloadData
    @world.setup_tree
    
    @menu.app = self
    @menu.pref = @pref
    @menu.world = @world
    @menu.window = @window
    @menu.tree = @tree
    @menu.member_list = @member_list
    @menu.text = @text
    
    @member_list.setTarget(@menu)
    @member_list.setDoubleAction('memberList_doubleClicked:')
    @member_list.key_delegate = @world
    #@member_list.tableColumnWithIdentifier('nick').setDataCell(MemberListCell.alloc.init)
    
    @dcc = DccManager.alloc.init
    @dcc.pref = @pref
    @dcc.world = @world
    @world.dcc = @dcc
    
    @history = InputHistory.new
  end
  
  def terminateWithoutConfirm(sender)
    @terminating = true
    NSApp.terminate(self)
  end
  
  def applicationDidFinishLaunching(sender)
    @world.start_timer
    @world.auto_connect
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
    @menu.terminate
    @world.terminate
    @dcc.save_window_state
    save_window_state
    #@world.save
  end
  
  def applicationDidBecomeActive(notification)
    sel = @world.selected
    sel.reset_state if sel
    @tree.setNeedsDisplay(true)
  end
  
  def applicationDidResignActive(notification)
    @tree.setNeedsDisplay(true)
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
  
  def preferences_changed
    @world.preferences_changed
  end
  
  def textEntered(sender)
    s = @text.stringValue.to_s
    unless s.empty?
      if @world.input_text(s)
        @history.add(s)
        @text.setStringValue('')
      end
    end
    @world.select_text
  end
  
  objc_method 'control:textView:doCommandBySelector:', 'c@:@@:'
  def control_textView_doCommandBySelector(control, textview, selector)
    case selector
    when 'moveUp:'
      s = @history.up
      if s
        @text.setStringValue(s)
        @world.select_text
      end
      true
    when 'moveDown:'
      s = @history.down(@text.stringValue.to_s)
      if s
        @text.setStringValue(s)
        @world.select_text
      end
      true
    else
      false
    end
  end
  
  def controlUp
    move(:up)
  end
  
  def controlDown
    move(:down)
  end
  
  def controlLeft
    move(:left)
  end
  
  def controlRight
    move(:right)
  end
  
  def commandUp
    move(:up, :active)
  end
  
  def commandDown
    move(:down, :active)
  end
  
  def commandLeft
    move(:left, :active)
  end
  
  def commandRight
    move(:right, :active)
  end
  
  def tab
    move(:down, :unread)
  end
  
  def controlTab
    move(:down, :unread)
  end
  
  def controlShiftTab
    move(:up, :unread)
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
  
  def number(n)
    @world.select_channel_at(n)
  end
  
  
  private

  def queryTerminate
    rec = @dcc.count_receiving_items
    send = @dcc.count_sending_items
    if rec > 0 || send > 0
      msg = "Now you are "
      if rec > 0
        msg += "receiving #{rec} files"
      end
      if send > 0
        msg += " and " if rec > 0
        msg += "sending #{send} files"
      end
      msg += ".\nAre you sure to quit?"
      return NSRunCriticalAlertPanel('LimeChat', msg, 'Anyway Quit', 'Cancel', nil) == NSAlertDefaultReturn
    elsif @pref.gen.confirm_quit
      NSRunCriticalAlertPanel('LimeChat', 'Are you sure to quit?', 'Quit', 'Cancel', nil) == NSAlertDefaultReturn
    else
      true
    end
  end
  
  def load_window_state
    win = @pref.load_window('main_window')
    if win
      f = NSRect.from_dic(win)
      @window.setFrame_display(f, true)
      @root_split.setPosition(win[:root])
      @log_split.setPosition(win[:log])
      @info_split.setPosition(win[:info])
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
    end
  end
  
  def save_window_state
    win = @window.frame.to_dic
    split = {
      :root => @root_split.position,
      :log => @log_split.position,
      :info => @info_split.position,
    }
    win.merge!(split)
    @pref.save_window('main_window', win)
  end

  def move(direction, target=:all)
    case direction
    when :up,:down
      sel = @world.selected
      return unless sel
      n = @tree.rowForItem(sel)
      return unless n
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
            if !i.unit? && i.active?
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
    when :left,:right
      sel = @world.selected
      return unless sel
      unit = sel.unit
      n = @world.units.index(unit)
      return unless n
      start = n
      size = @world.units.length
      loop do
        if direction == :left
          n -= 1
          n = size - 1 if n < 0
        else
          n += 1
          n = 0 if n >= size
        end
        break if n == start
        unit = @world.units[n]
        if unit
          case target
          when :active
            if unit.login?
              t = unit.last_selected_channel
              t = unit unless t
              @world.select(t)
              break
            end
          else
            t = unit.last_selected_channel
            t = unit unless t
            @world.select(t)
            break
          end
        end
      end
    end
  end
end
