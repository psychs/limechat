# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'date'

class AIRCWorld < NSObject
  attr_accessor :memberList, :dcc, :viewTheme, :window
  attr_writer :app, :tree, :logBase, :consoleBase, :chatBox, :fieldEditor, :text
  attr_accessor :menuController
  attr_accessor :serverMenu, :channelMenu, :treeMenu, :logMenu
  attr_accessor :consoleMenu, :urlMenu, :addrMenu, :chanMenu, :memberMenu
  attr_reader :clients, :selected, :prevSelected, :console, :config

  AUTO_CONNECT_DELAY = 1
  RECONNECT_AFTER_WAKE_UP_DELAY = 5

  def initialize
    @clients = []
    @client_id = 0
    @channel_id = 0
    @growl = GrowlController.alloc.init
    @icon = IconController.alloc.init
    @growl.owner = self
    @today = Date.today
  end

  def setup(seed)
    @console = create_log(nil, nil, true)
    @consoleBase.setContentView(@console.view)
    @dummylog = create_log(nil, nil, true)
    @logBase.setContentView(@dummylog.view)

    @config = seed.dup
    @config.clients.each {|u| create_client(u) } if @config.clients
    @config.clients = nil

    change_input_text_theme
    change_memberList_theme
    change_tree_theme
    register_growl

    #@plugin = PluginManager.new(self, '~/Library/LimeChat/Plugins')
    #@plugin.load_all
  end

  def save
    preferences.save_world(dictionaryValue)
  end

  def setupTree
    @tree.setTarget(self)
    @tree.setDoubleAction('outlineView_doubleClicked:')
  	@tree.registerForDraggedTypes(TREE_DRAG_ITEM_TYPES);

    client = @clients.find {|u| u.config.autoConnect }
    if client
      expand_client(client)
      unless client.channels.empty?
        @tree.select(@tree.rowForItem(client)+1)
      else
        @tree.select(@tree.rowForItem(client))
      end
    elsif @clients.size > 0
      select(@clients[0])
    end
    outlineViewSelectionDidChange(nil)
  end

  def terminate
    @clients.each {|u| u.terminate }
  end

  def update_order(w)
    ary = []
    w.clients.each do |i|
      u = find_client_by_id(i.uid)
      if u
        u.update_order(i)
        ary << u
        @clients.delete(u)
      end
    end
    ary += @clients
    @clients = ary
    reload_tree
    adjust_selection
    save
  end

  def updateAutoOp(w)
    @config.autoop = w.autoop
    w.clients.each do |i|
      u = find_client_by_id(i.uid)
      u.updateAutoOp(i) if u
    end
    save
  end

  def store_tree
    w = @config.dup
    w.clients = @clients.map {|u| u.store_config }
    w
  end

  def autoConnect(after_wake_up=false)
    delay = 0
    delay += RECONNECT_AFTER_WAKE_UP_DELAY if after_wake_up
    @clients.each do |u|
      if (!after_wake_up) && u.config.autoConnect || after_wake_up && u.reconnect
        u.autoConnect(delay)
        delay += AUTO_CONNECT_DELAY
      end
    end
  end

  def prepare_for_sleep
    @clients.each {|u| u.disconnect(true) }
  end

  def selclient
    return nil unless @selected
    @selected.client? ? @selected : @selected.client
  end

  def selchannel
    return nil unless @selected
    @selected.client? ? nil : @selected
  end

  def sel
    [selclient, selchannel]
  end

  def dictionaryValue
    h = @config.dictionaryValue
    unless @clients.empty?
      h[:clients] = @clients.map {|i| i.dictionaryValue }
    end
    h
  end

  def find_client(name)
    @clients.find {|u| u.name == name }
  end

  def find_client_by_id(uid)
    @clients.find {|u| u.uid == uid }
  end

  def find_channel_by_id(uid, cid)
    client = @clients.find {|u| u.uid == uid }
    return nil unless client
    client.channels.find {|c| c.uid == cid }
  end

  def find_by_id(uid, cid)
    client = find_client_by_id(uid)
    return [] unless client
    channel = client.find_channel_by_id(cid)
    [client, channel]
  end

  def create_client(seed, reload=true)
    @client_id += 1
    u = IRCClient.alloc.init
    u.uid = @client_id
    u.world = self
    u.log = create_log(u)
    u.setup(seed)
    seed.channels.each {|c| create_channel(u, c) } if seed.channels
    @clients << u
    reload_tree if reload
    u
  end

  def destroy_client(client)
    client.terminate
    client.disconnect
    if @selected && @selected.client == client
      select_other_and_destroy(client)
    else
      @clients.delete(client)
      reload_tree
      adjust_selection
    end
  end

  def create_channel(client, seed, reload=true, adjust=true)
    c = client.find_channel(seed.name)
    return c if c

    @channel_id += 1
    c = IRCChannel.alloc.init
    c.uid = @channel_id
    c.client = client
    c.setup(seed)
    c.log = create_log(client, c)

    case seed.type
    when :channel
      n = client.channels.index {|i| i.talk? }
      if n
        client.channels.insert(n, c)
      else
        client.channels << c
      end
    when :talk
      n = client.channels.index {|i| i.dccchat? }
      if n
        client.channels.insert(n, c)
      else
        client.channels << c
      end
    when :dccchat
      client.channels << c
    end

    reload_tree if reload
    adjust_selection if adjust
    expand_client(client) if client.login? && client.channels.size == 1
    c
  end

  def create_talk(client, nick)
    c = create_channel(client, IRCChannelConfig.new({:name => nick, :type => :talk}))
    if client.login?
      c.activate
      
      m = IRCUser.alloc.init
      m.nick = client.mynick
      c.addMember_reload(m)
      
      m = IRCUser.alloc.init
      m.nick = nick
      c.addMember_reload(m)
    end
    c
  end

  def destroy_channel(channel)
    channel.terminate
    client = channel.client
    case channel.type
    when :channel
      client.part_channel(channel) if client.login? && channel.active?
    when :talk
    when :dccchat
    end
    if client.last_selected_channel == channel
      client.last_selected_channel = nil
    end
    if @selected == channel
      select_other_and_destroy(channel)
    else
      client.channels.delete(channel)
      reload_tree
      adjust_selection
    end
  end

  def adjust_selection
    row = @tree.selectedRow
    if row >= 0 && @selected && @selected != @tree.itemAtRow(row)
      @tree.select(@tree.rowForItem(@selected))
      reload_tree
    end
  end

  def clear_text
    @text.setStringValue('')
  end

  def input_text(s, cmd)
    return false unless @selected
    @selected.client.input_text(s, cmd)
  end

  def select_text
    @text.focus
  end

  def store_prevSelected
    if !@selected
      @prevSelected = nil
    elsif @selected.client?
      @prevSelected = [@selected.uid, nil]
    else
      @prevSelected = [@selected.client.uid, @selected.uid]
    end
  end

  def select_prev
    return unless @prevSelected
    uid, cid = @prevSelected
    if cid
      i = find_channel_by_id(uid, cid)
    else
      i = find_client_by_id(uid)
    end
    select(i) if i
  end

  def select(item)
    store_prevSelected
    select_text
    unless item
      @selected = nil
      @logBase.setContentView(@dummylog.view)
      @memberList.setDataSource(nil)
      @memberList.reloadData
      @tree.setMenu(@treeMenu)
      return
    end
    @tree.expandItem(item.client) unless item.client?
    i = @tree.rowForItem(item)
    return if i < 0
    @tree.select(i)
    item.client.last_selected_channel = item.client? ? nil : item
  end

  def select_channel_at(n)
    return unless @selected
    client = @selected.client
    return select(client) if n == 0
    n -= 1
    channel = client.channels[n]
    select(channel) if channel
  end

  def select_client_at(n)
    client = @clients[n]
    return unless client
    t = client.last_selected_channel
    t = client unless t
    select(t)
  end

  def expand_client(client)
    @tree.expandItem(client)
  end

  def update_client_title(client)
    return unless client && @selected
    update_title if @selected.client == client
  end

  def updateChannelTitle(channel)
    return unless channel
    update_title if @selected == channel
  end

  def update_title
    if @selected
      sel = @selected
      if sel.client?
        u = sel
        nick = u.mynick
        mymode = u.mymode.to_s
        name = u.config.name
        title =
          if nick.empty?
            "#{name}"
          elsif mymode.empty?
            "(#{nick}) #{name}"
          else
            "(#{nick}) (#{mymode}) #{name}"
          end
        @window.setTitle(title)
      else
        u = sel.client
        c = sel
        nick = u.mynick
        chname = c.name
        count = c.countMembers
        mode = c.mode.masked_str
        topic = c.topic
        if topic =~ /\A(.{25})/
          topic = $1 + '...'
        end
        title =
          if c.channel?
            op = if c.isOp?
              m = c.findMember(u.mynick)
              if m && m.isOp?
                m.mark
              else
                ''
              end
            else
              ''
            end

            if mode.empty?
              if count <= 1
                "(#{nick}) #{op}#{chname} #{topic}"
              else
                "(#{nick}) #{op}#{chname} (#{count}) #{topic}"
              end
            else
              if count <= 1
                "(#{nick}) #{op}#{chname} (#{mode}) #{topic}"
              else
                "(#{nick}) #{op}#{chname} (#{count},#{mode}) #{topic}"
              end
            end
          else
            "(#{nick}) #{chname}"
          end
        @window.setTitle(title)
      end
    end
  end

  def reload_tree
    if @reloading_tree
      @tree.setNeedsDisplay(true)
      return
    end
    @reloading_tree = true
    @tree.reloadData
    @reloading_tree = false
  end

  def register_growl
    @growl.register if preferences.general.use_growl
  end

  def notify_on_growl(kind, title, desc, context=nil)
    if preferences.general.use_growl
      register_growl
      return if preferences.general.stop_growl_on_active && NSApp.isActive
      @growl.notify(kind, title, desc, context)
    end
  end

  def update_icon
    highlight = newtalk = false

    @clients.each do |u|
      if u.keyword
        highlight = true
        break
      end

      u.channels.each do |c|
        if c.keyword
          highlight = true
          break
        end
        newtalk = true if c.newtalk
      end
    end

    @icon.setHighlight_newTalk(highlight, newtalk)
  end

  def reloadTheme
    @viewTheme.theme = preferences.theme.name

    logs = [@console]

    @clients.each do |u|
      logs << u.log
      u.channels.each do |c|
        logs << c.log
      end
    end

    logs.each do |log|
      if preferences.theme.override_log_font
        log.overrideFont = [preferences.theme.log_font_name, preferences.theme.log_font_size]
      else
        log.overrideFont = nil
      end
      log.reloadTheme
    end

    change_input_text_theme
    change_tree_theme
    change_memberList_theme

    #sel = selected
    #@logBase.setContentView(sel.log.view) if sel
    #@consoleBase.setContentView(@console.view)
  end

  def change_input_text_theme
    theme = @viewTheme.other
    @fieldEditor.setInsertionPointColor(theme.input_text_color)
    @text.setTextColor(theme.input_text_color)
    @text.setBackgroundColor(theme.input_text_bgcolor)
    @chatBox.setInputTextFont(theme.input_text_font)
  end

  def change_tree_theme
    theme = @viewTheme.other
    @tree.setFont(theme.tree_font)
    @tree.themeChanged
    @tree.setNeedsDisplay(true)
  end

  def change_memberList_theme
    theme = @viewTheme.other
    @memberList.setFont(theme.memberList_font)
    @memberList.tableColumns[0].dataCell.themeChanged
    @memberList.themeChanged
    @memberList.setNeedsDisplay(true)
  end

  def preferencesChanged
    @console.maxLines = preferences.general.max_log_lines
    @clients.each {|u| u.preferencesChanged}
    reloadTheme
  end

  def dateChanged
    @clients.each {|u| u.dateChanged}
  end

  def changeTextSize(op)
    logs = [@console]
    @clients.each do |u|
      logs << u.log
      u.channels.each do |c|
        logs << c.log
      end
    end
    logs.each {|i| i.changeTextSize(op)}
  end

  def reload_plugins
    #@plugin.load_all
  end

  def mark_all_as_read
    @clients.each do |u|
      u.unread = false
      u.channels.each do |c|
        c.unread = false
      end
    end
    reload_tree
  end

  def mark_all_scrollbacks
    @clients.each do |u|
      u.log.mark
      u.channels.each do |c|
        c.log.mark
      end
    end
  end

  # delegate

  def outlineView_doubleClicked(sender)
    return unless @selected
    u, c = sel
    unless c
      if u.connecting? || u.connected? || u.login?
        u.quit if preferences.general.disconnect_on_doubleclick
      else
        u.connect if preferences.general.connect_on_doubleclick
      end
    else
      if u.login?
        if c.active?
          u.part_channel(c) if preferences.general.leave_on_doubleclick
        else
          u.join_channel(c) if preferences.general.join_on_doubleclick
        end
      end
    end
  end

  def outlineView_shouldEditTableColumn_item(sender, column, item)
    false
  end

  def outlineViewSelectionIsChanging(note)
    store_prevSelected
    outlineViewSelectionDidChange(note)
  end

  def outlineViewSelectionDidChange(note)
    selitem = @tree.itemAtRow(@tree.selectedRow)
    if @selected != selitem
      @selected.lastInputText = @text.stringValue.to_s if @selected
      @app.addToHistory
      if selitem
        @text.setStringValue(selitem.lastInputText || '')
      else
        @text.setStringValue('')
      end
      select_text
    end
    unless selitem
      @logBase.setContentView(@dummylog.view)
      @tree.setMenu(@treeMenu)
      @memberList.setDataSource(nil)
      @memberList.setDelegate(nil)
      @memberList.reloadData
      return
    end
    selitem.resetState
    @selected = selitem
    @logBase.setContentView(selitem.log.view)
    if selitem.client?
      @tree.setMenu(@serverMenu.submenu)
      @memberList.setDataSource(nil)
      @memberList.setDelegate(nil)
      @memberList.reloadData
      selitem.last_selected_channel = nil
    else
      @tree.setMenu(@channelMenu.submenu)
      @memberList.setDataSource(selitem)
      @memberList.setDelegate(selitem)
      @memberList.reloadData
      selitem.client.last_selected_channel = selitem
    end
    @memberList.deselectAll(self)
    @memberList.scrollRowToVisible(0)
    @selected.log.view.clearSel
    update_title
    reload_tree
    update_icon
  end

  def outlineViewItemDidCollapse(notification)
    item = notification.userInfo.objectForKey('NSObject')
    select(item) if item
  end

  # data source

  def outlineView_numberOfChildrenOfItem(sender, item)
    return @clients.size unless item
    item.numberOfChildren
  end

  def outlineView_isItemExpandable(sender, item)
    item.numberOfChildren > 0
  end

  def outlineView_child_ofItem(sender, index, item)
    return @clients[index] unless item
    item.childAt(index)
  end

  def outlineView_objectValueForTableColumn_byItem(sender, column, item)
    item.label
  end

  # tree

  def serverTreeViewAcceptsFirstResponder
    select_text
  end

  def outlineView_willDisplayCell_forTableColumn_item(sender, cell, col, item)
    theme = @viewTheme.other

    if item.keyword
      textcolor = theme.tree_highlight_color
    elsif item.newtalk
      textcolor = theme.tree_newtalk_color
    elsif item.unread
      textcolor = theme.tree_unread_color
    elsif item.client? ? item.login? : item.active?
      if item == @tree.itemAtRow(@tree.selectedRow) && NSApp.isActive
        textcolor = theme.tree_sel_active_color
      else
        textcolor = theme.tree_active_color
      end
    else
      if item == @tree.itemAtRow(@tree.selectedRow)
        textcolor = theme.tree_sel_inactive_color
      else
        textcolor = theme.tree_inactive_color
      end
    end
    cell.setTextColor(textcolor)
  end

  # tree drag and drop

  TREE_DRAG_ITEM_TYPE = 'treeitem'
  TREE_DRAG_ITEM_TYPES = [TREE_DRAG_ITEM_TYPE]

  def outlineView_writeItems_toPasteboard(sender, items, pboard)
    i = items.to_a[0]
    if i.is_a?(IRCClient)
      s = "#{i.uid}"
    else
      s = "#{i.client.uid}-#{i.uid}"
    end
    pboard.declareTypes_owner(TREE_DRAG_ITEM_TYPES, self)
    pboard.setPropertyList_forType(s, TREE_DRAG_ITEM_TYPE)
    true
  end

  def find_item_from_pboard(s)
    if /^(\d+)-(\d+)$/ =~ s
      u = $1.to_i
      c = $2.to_i
      find_channel_by_id(u, c)
    elsif /^\d+$/ =~ s
      find_client_by_id(s.to_i)
    else
      nil
    end
  end

  def outlineView_validateDrop_proposedItem_proposedChildIndex(sender, info, item, index)
    return NSDragOperationNone if index < 0
  	pboard = info.draggingPasteboard
  	return NSDragOperationNone unless pboard.availableTypeFromArray(TREE_DRAG_ITEM_TYPES)
    target = pboard.propertyListForType(TREE_DRAG_ITEM_TYPE)
    return NSDragOperationNone unless target
    i = find_item_from_pboard(target.to_s)
    return NSDragOperationNone unless i

    if i.is_a?(IRCClient)
      return NSDragOperationNone if item
    else
      return NSDragOperationNone unless item
      return NSDragOperationNone if item != i.client
      if i.talk?
        ary = item.channels
        low = ary[0...index] || []
        high = ary[index...ary.size] || []
        low.delete(i)
        high.delete(i)
        next_item = high[0]

        # don't allow talks dropped above channels
        return NSDragOperationNone if next_item && next_item.channel?
      end
    end
    NSDragOperationGeneric
  end

  def outlineView_acceptDrop_item_childIndex(sender, info, item, index)
    return false if index < 0
  	pboard = info.draggingPasteboard
  	return false unless pboard.availableTypeFromArray(TREE_DRAG_ITEM_TYPES)
    target = pboard.propertyListForType(TREE_DRAG_ITEM_TYPE)
    return false unless target
    i = find_item_from_pboard(target.to_s)
    return false unless i

    if i.is_a?(IRCClient)
      return false if item

      ary = @clients
      low = ary[0...index] || []
      high = ary[index...ary.size] || []
      low.delete(i)
      high.delete(i)
      @clients.replace(low + [i] + high)
      reload_tree
      save
    else
      return false unless item
      return false if item != i.client

      ary = item.channels
      low = ary[0...index] || []
      high = ary[index...ary.size] || []
      low.delete(i)
      high.delete(i)
      item.channels.replace(low + [i] + high)
      reload_tree
      save if i.channel?
    end
    adjust_selection
    true
  end

  # log view

  def log_doubleClick(s)
    ary = s.split(' ')
    case ary[0]
    when 'client'
      uid = ary[1].to_i
      client = find_client_by_id(uid)
      select(client) if client
    when 'channel'
      uid = ary[1].to_i
      cid = ary[2].to_i
      channel = find_channel_by_id(uid, cid)
      select(channel) if channel
    end
  end

  def log_keyDown(e)
    @window.makeFirstResponder(@text)
    select_text
    case e.keyCode.to_i
    when 36,76  # enter / num_enter
      ;
    else
      @window.sendEvent(e)
    end
  end

  # list view

  def memberListViewKeyDown(e)
    @window.makeFirstResponder(@text)
    select_text
    case e.keyCode.to_i
    when 36,76  # enter / num_enter
      ;
    else
      @window.sendEvent(e)
    end
  end

  def memberListViewDropFiles_row(files, row)
    u, c = sel
    return unless u && c
    m = c.members[row.to_i]
    if m
      files.to_a.each {|f| @dcc.add_sender(u.uid, m.nick, f, false) }
    end
  end

  # timer

  def onTimer
    @clients.each {|u| u.onTimer }
    @dcc.onTimer

    date = Date.today
    if @today != date
      @today = date
      dateChanged
    end
  end

  private

  def select_other_and_destroy(target)
    if target.client?
      i = @clients.index(target)
      sel = @clients[i+1]
      i = @tree.rowForItem(target)
    else
      i = @tree.rowForItem(target)
      sel = @tree.itemAtRow(i+1)
      if sel && sel.client?
        # we don't want to change clients when closing a channel
        sel = @tree.itemAtRow(i-1)
      end
    end
    if sel
      select(sel)
    else
      sel = @tree.itemAtRow(i-1)
      if sel
        select(sel)
      else
        select(nil)
      end
    end
    if target.client?
      target.channels.each {|c| c.closeDialogs }
      @clients.delete(target)
    else
      target.client.channels.delete(target)
    end
    reload_tree
    if @selected
      i = @tree.rowForItem(sel)
      @tree.select(i)
    end
  end

  def create_log(client, channel=nil, console=false)
    log = LogController.alloc.init
    log.menu = console ? @consoleMenu : @logMenu
    log.urlMenu = @urlMenu
    log.addrMenu = @addrMenu
    log.chanMenu = @chanMenu
    log.memberMenu = @memberMenu
    log.world = self
    log.client = client
    log.channel = channel
    log.keyword = preferences.keyword
    log.maxLines = preferences.general.max_log_lines
    log.theme = @viewTheme
    if preferences.theme.override_log_font
      log.overrideFont = [preferences.theme.log_font_name, preferences.theme.log_font_size]
    else
      log.overrideFont = nil
    end
    log.console = console
    log.initialBackgroundColor = @viewTheme.other.input_text_bgcolor
    log.setUp
    log.view.setHostWindow(@window)
    log.view.setTextSizeMultiplier(@console.view.textSizeMultiplier) if @console
    log
  end

end
