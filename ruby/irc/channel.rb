# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class IRCChannel < NSObject
  attr_accessor :unit, :id, :topic, :names_init, :who_init, :log
  attr_reader :config, :members, :mode
  attr_writer :op
  attr_accessor :keyword, :unread, :newtalk
  attr_accessor :property_dialog
  attr_accessor :stored_topic
  attr_accessor :last_input_text
  
  def initialize
    @topic = ''
    @members = []
    @mode = ChannelMode.new
    @op = false
    @active = false
    @names_init = false
    @who_init = false
    @op_queue = []
    @op_wait = 0
    @terminating = false
    reset_state
  end
  
  def reset_state
    @keyword = @unread = @newtalk = false
  end
  
  def setup(seed)
    @config = seed.dup
    @mode.info = @unit.isupport.mode
  end
  
  def update_config(seed)
    @config = seed.dup
  end

  def update_autoop(conf)
    @config.autoop = conf.autoop
  end
  
  def terminate
    @terminating = true
    close_dialogs
    close_logfile
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
  
  def to_dic
    @config.to_dic
  end
  
  def unit?
    false
  end
  
  def type
    @config.type
  end
  
  def channel?
    @config.type == :channel
  end
  
  def talk?
    @config.type == :talk
  end
  
  def dccchat?
    @config.type == :dccchat
  end
  
  def active?
    @active
  end
  
  def op?
    @op
  end
  
  def activate
    @active = true
    @members.clear
    @mode.clear
    @op = false
    @topic = ''
    @names_init = false
    @who_init = false
    @op_queue = []
    @op_wait = 0
    reload_members
  end
  
  def deactivate
    @active = false
    @members.clear
    @op = false
    @op_queue = []
    reload_members
  end
  
  def close_dialogs
    if @property_dialog
      @property_dialog.close
      @property_dialog = nil
    end
  end
  
  def add_member(member, autoreload=true)
    if i = find_member_index(member.nick)
      m = @members[i]
      m.username = member.username unless member.username.empty?
      m.address = member.username unless member.address.empty?
      m.q = member.q
      m.a = member.a
      m.o = member.o
      m.h = member.h
      m.v = member.v
      @members.delete_at(i)
      sorted_insert(m)
    else
      sorted_insert(member)
    end
    
    reload_members if autoreload
  end
  
  def remove_member(nick, autoreload=true)
    t = nick.downcase
    @members.delete_if {|m| m.nick.downcase == t }
    @op_queue.delete_if {|i| i.downcase == t }
    
    reload_members if autoreload
  end
  
  def rename_member(nick, tonick)
    i = find_member_index(nick)
    return unless i
    
    remove_member(tonick, false)
    
    m = @members[i]
    m.nick = tonick
    @members.delete_at(i)
    sorted_insert(m)

    # update op queue
    #
    t = nick.downcase
    index = @op_queue.index {|i| i.downcase == t }
    if index
      @op_queue.delete_at(index)
      @op_queue << tonick
    end
    
    reload_members
  end
  
  def update_or_add_member(nick, username, address, q, a, o, h, v)
    i = find_member_index(nick)
    unless i
      sorted_insert(User.new(nick, username, address, q, a, o, h, v))
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
    sorted_insert(m)
  end
  
  def change_member_op(nick, type, value)
    i = find_member_index(nick)
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
    sorted_insert(m)
    
    # update op queue
    #
    if type == :o && value
      t = nick.downcase
      @op_queue.delete_if {|i| i.downcase == t }
    end
    
    reload_members
  end
  
  def clear_members
    @members.clear
    reload_members
  end
  
  def find_member_index(nick)
    t = nick.downcase
    @members.index {|m| m.nick.downcase == t }
  end
  
  def find_member(nick)
    t = nick.downcase
    @members.find {|m| m.nick.downcase == t }
  end
  
  def count_members
    @members.size
  end
  
  def reload_members
    if @unit.world.selected == self
      @unit.world.member_list.reloadData
    end
  end
  
  def sorted_insert(item)
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
        @members.insert idx, item
        return
      end
    end
    @members.insert tail, item
  end
  
  def compare_members(a, b)
    if unit.mynick == a.nick
      -1
    elsif unit.mynick == b.nick
      1
    elsif a.q != b.q
      a.q ? -1 : 1
    elsif a.q && b.q
      a.nick.casecmp(b.nick)
    elsif a.a != b.a
      a.a ? -1 : 1
    elsif a.a && b.a
      a.nick.casecmp(b.nick)
    elsif a.o != b.o
      a.o ? -1 : 1
    elsif a.o && b.o
      a.nick.casecmp(b.nick)
    elsif a.h != b.h
      a.h ? -1 : 1
    elsif a.h && b.h
      a.nick.casecmp(b.nick)
    elsif a.v != b.v
      a.v ? -1 : 1
    else
      a.nick.casecmp(b.nick)
    end
  end
  
  def check_autoop(nick, mask)
    if @config.match_autoop(mask) || @unit.config.match_autoop(mask) || @unit.world.config.match_autoop(mask)
      add_to_op_queue(nick)
    end
  end
  
  def check_all_autoop
    @members.each do |m|
      if !m.nick.empty? && !m.username.empty? && !m.address.empty?
        check_autoop(m.nick, "#{m.nick}!#{m.username}@#{m.address}")
      end
    end
  end
  
  def add_to_op_queue(nick)
    t = nick.downcase
    unless @op_queue.find {|i| i.downcase == t }
      @op_queue << nick.dup
    end
  end
  
  def print(line)
    result = @log.print(line, @unit)
    
    # open log file
    unless @terminating
      if preferences.general.log_transcript
        unless @logfile
          @logfile = FileLogger.new(@unit, self)
        end
        nickstr = line.nick ? "#{line.nick_info}: " : ""
        s = "#{line.time}#{nickstr}#{line.body}"
        @logfile.write_line(s)
      end
    end
    
    result
  end
  
  # model
  
  def number_of_children
    0
  end

  def child_at(index)
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
  
  def on_timer
    if active?
      @op_wait -= 1 if @op_wait > 0
      if @unit.ready_to_send? && @op_wait == 0 && @op_queue.size > 0
        max = @unit.isupport.modes_count
        ary = @op_queue[0...max]
        @op_queue[0...max] = nil
        ary = ary.select {|i| m = find_member(i); m && !m.op? }
        unless ary.empty?
          @op_wait = ary.size * Penalty::MODE_OPT + Penalty::MODE_BASE
          @unit.change_op(self, ary, :o, true)
        end
      end
    end
  end
  
  def preferences_changed
    if @logfile
      if preferences.general.log_transcript
        @logfile.reopen_if_needed
      else
        close_logfile
      end
    end
    @log.max_lines = preferences.general.max_log_lines
  end
  
  def date_changed
    @logfile.reopen_if_needed if @logfile
  end
  
  private
  
  def update_channel_title
    @unit.update_channel_title(self)
  end
  
  def close_logfile
    if @logfile
      @logfile.close
      @logfile = nil
    end
  end
end
