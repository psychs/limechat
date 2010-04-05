# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class AIRCChannel < NSObject
  attr_accessor :client, :uid, :topic, :namesInit, :whoInit, :log
  attr_reader :config, :members, :mode
  attr_writer :op
  attr_accessor :keyword, :unread, :newtalk
  attr_accessor :propertyDialog
  attr_accessor :storedTopic
  attr_accessor :lastInputText
  
  def initialize
    @topic = ''
    @members = []
    @mode = ChannelMode.new
    @op = false
    @active = false
    @namesInit = false
    @whoInit = false
    @op_queue = []
    @op_wait = 0
    @terminating = false
    resetState
  end
  
  def resetState
    @keyword = @unread = @newtalk = false
  end
  
  def setup(seed)
    @config = seed.dup
    @mode.info = @client.isupport
  end
  
  def updateConfig(seed)
    @config = seed.dup
  end

  def updateAutoOp(conf)
    @config.autoop = conf.autoop
  end
  
  def terminate
    @terminating = true
    closeDialogs
    closeLogFile
  end
  
  def name
    @config.name
  end
  
  def name=(value)
    @config.name = value
  end
  
  def password
    return '' unless @config.password
    @config.password
  end
  
  def dictionaryValue
    @config.dictionaryValue
  end
  
  def client?
    false
  end
  
  objc_method 'isClient', 'i@:'
  def isClient
    client?
  end
  
  def type
    @config.type
  end
  
  def typeStr
    @config.type.to_s
  end
  
  def channel?
    @config.type == :channel
  end
  
  objc_method 'isChannel', 'i@:'
  def isChannel
    channel?
  end
  
  def talk?
    @config.type == :talk
  end
  
  objc_method 'isTalk', 'i@:'
  def isTalk
    talk?
  end
  
  def dccchat?
    @config.type == :dccchat
  end
  
  objc_method 'isDCCChat', 'i@:'
  def isDCCChat
    dccchat?
  end
  
  def active?
    @active
  end
  
  def isOp?
    @op
  end
  
  def activate
    @active = true
    @members.clear
    @mode.clear
    @op = false
    @topic = ''
    @namesInit = false
    @whoInit = false
    @op_queue = []
    @op_wait = 0
    reloadMembers
  end
  
  def deactivate
    @active = false
    @members.clear
    @op = false
    @op_queue = []
    reloadMembers
  end
  
  def closeDialogs
    if @propertyDialog
      @propertyDialog.close
      @propertyDialog = nil
    end
  end
  
  def addMember_reload(member, autoreload=true)
    if i = findMemberIndex(member.nick)
      m = @members[i]
      m.username = member.username
      m.address = member.address
      m.q = member.q
      m.a = member.a
      m.o = member.o
      m.h = member.h
      m.v = member.v
      @members.delete_at(i)
      sortedInsert(m)
    else
      sortedInsert(member)
    end
    
    reloadMembers if autoreload
  end
  
  def removeMember_reload(nick, autoreload=true)
    if i = findMemberIndex(nick)
      @members.delete_at(i)
    end
    removeFromOpQueue(nick)
    
    reloadMembers if autoreload
  end
  
  def renameMember_to(nick, tonick)
    i = findMemberIndex(nick)
    return unless i
    
    m = @members[i]
    removeMember_reload(tonick, false)
    m.nick = tonick
    @members.delete_at(i)
    sortedInsert(m)

    # update op queue
    #
    t = nick.downcase
    index = @op_queue.index {|i| i == t }
    if index
      @op_queue.delete_at(index)
      @op_queue << tonick.downcase
    end
    
    reloadMembers
  end
  
  def updateOrAddMember_username_address_q_a_o_h_v(nick, username, address, q, a, o, h, v)
    i = findMemberIndex(nick)
    unless i
      m = IRCUser.alloc.init
      m.nick = nick
      m.username = username
      m.address = address
      m.q = q
      m.a = a
      m.o = h
      m.h = h
      m.v = v
      sortedInsert(m)
      return
    end
    
    m = @members[i]
    m.username = username
    m.address = address
    m.q = q
    m.a = a
    m.o = o
    m.h = h
    m.v = v
    
    @members.delete_at(i)
    sortedInsert(m)
  end
  
  def changeMember_mode_value(nick, type, value)
    i = findMemberIndex(nick)
    return unless i
    
    m = @members[i]
    
    case type
    when :q; m.q = value
    when :a; m.a = value
    when :o; m.o = value
    when :h; m.h = value
    when :v; m.v = value
    end
    
    @members.delete_at(i)
    sortedInsert(m)
    
    # update op queue
    #
    if (type == :o || type == :a || type == :q) && value
      removeFromOpQueue(nick)
    end
    
    reloadMembers
  end
  
  def clearMembers
    @members.clear
    reloadMembers
  end
  
  def findMemberIndex(nick)
    t = nick.downcase
    @members.index {|m| m.canonicalNick == t }
  end
  
  def findMember(nick)
    t = nick.downcase
    @members.find {|m| m.canonicalNick == t }
  end
  
  def countMembers
    @members.size
  end
  
  def reloadMembers
    if @client.world.selected == self
      @client.world.memberList.reloadData
    end
  end
  
  def sortedInsert(item)
    # do a binary search
    # once the range hits a length of 5 (arbitrary)
    # switch to linear search
    head = 0
    tail = @members.size
    while tail - head > 5
      pivot = (head + tail) / 2
      if compare_members(@members[pivot], item) > 0
        tail = pivot
      else
        head = pivot
      end
    end
    head.upto(tail-1) do |idx|
      if compare_members(@members[idx], item) > 0
        @members.insert(idx, item)
        return
      end
    end
    @members.insert(tail, item)
  end
  
  def compare_members(a, b)
    if client.mynick == a.nick
      -1
    elsif client.mynick == b.nick
      1
    elsif a.q != b.q
      a.q ? -1 : 1
    elsif a.q && b.q
      a.canonicalNick <=> b.canonicalNick
    elsif a.a != b.a
      a.a ? -1 : 1
    elsif a.a && b.a
      a.canonicalNick <=> b.canonicalNick
    elsif a.o != b.o
      a.o ? -1 : 1
    elsif a.o && b.o
      a.canonicalNick <=> b.canonicalNick
    elsif a.h != b.h
      a.h ? -1 : 1
    elsif a.h && b.h
      a.canonicalNick <=> b.canonicalNick
    elsif a.v != b.v
      a.v ? -1 : 1
    else
      a.canonicalNick <=> b.canonicalNick
    end
  end
  
  def checkAutoop_mask(nick, mask)
    if @config.match_autoop(mask) || @client.config.match_autoop(mask) || @client.world.config.match_autoop(mask)
      addToOpQueue(nick)
    end
  end
  
  def checkAllAutoOp
    @members.each do |m|
      if !m.isOp? && !m.nick.empty? && !m.username.empty? && !m.address.empty?
        checkAutoop_mask(m.nick, "#{m.nick}!#{m.username}@#{m.address}")
      end
    end
  end
  
  def addToOpQueue(nick)
    t = nick.downcase
    unless @op_queue.find {|i| i == t }
      @op_queue << t
    end
  end
  
  def removeFromOpQueue(nick)
    t = nick.downcase
    if index = @op_queue.index {|i| i == t }
      @op_queue.delete_at(index)
    end
  end
  
  def print(line)
    result = @log.print_useKeyword(line, true)
    
    # open log file
    unless @terminating
      if preferences.general.log_transcript
        unless @logfile
          @logfile = FileLogger.alloc.init
          @logfile.client = @client
          @logfile.channel = self
        end
        nickstr = line.nick ? "#{line.nick_info}: " : ""
        s = "#{line.time}#{nickstr}#{line.body}"
        @logfile.writeLine(s)
      end
    end
    
    result
  end
  
  # model
  
  def numberOfChildren
    0
  end

  def childAt(index)
    nil
  end

  def label
    if !@cached_label || !@cached_label.isEqualToString?(name)
      @cached_label = name.to_ns
    end
    @cached_label
  end
  
  # table
  
  def numberOfRowsInTableView(sender)
    @members.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    ''
  end
  
  def tableView_willDisplayCell_forTableColumn_row(sender, cell, col, row)
    m = @members[row]
    #cell.setHighlighted(sender.isRowSelected(row))
    cell.member = m
  end
  
  # timer
  
  def onTimer
    if active?
      @op_wait -= 1 if @op_wait > 0
      if @client.ready_to_send? && @op_wait == 0 && @op_queue.size > 0
        max = @client.isupport.modes_count
        ary = @op_queue[0...max]
        @op_queue[0...max] = nil
        ary = ary.select {|i| m = findMember(i); m && !m.isOp? }
        unless ary.empty?
          @op_wait = ary.size * Penalty::MODE_OPT + Penalty::MODE_BASE
          @client.change_op(self, ary, :o, true)
        end
      end
    end
  end
  
  def preferencesChanged
    if @logfile
      if preferences.general.log_transcript
        @logfile.reopenIfNeeded
      else
        closeLogFile
      end
    end
    @log.maxLines = preferences.general.max_log_lines
  end
  
  def dateChanged
    @logfile.reopenIfNeeded if @logfile
  end
  
  private
  
  def updateChannelTitle
    @client.updateChannelTitle(self)
  end
  
  def closeLogFile
    if @logfile
      @logfile.close
      @logfile = nil
    end
  end
end
