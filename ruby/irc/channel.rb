# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class IRCChannel < OSX::NSObject
  include OSX
  attr_accessor :unit, :id, :topic, :names_init, :who_init, :log
  attr_reader :config, :members, :mode
  attr_writer :op
  attr_accessor :keyword, :unread, :newtalk
  attr_accessor :property_dialog
  attr_accessor :stored_topic
  
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
    reset_state
  end
  
  def reset_state
    @keyword = @unread = @newtalk = false
  end
  
  def setup(seed)
    @config = seed.dup
  end
  
  def update_config(seed)
    @config = seed.dup
  end

  def update_autoop(conf)
    @config.autoop = conf.autoop
  end
  
  def terminate
    close_dialog
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
  
  def close_dialog
    if @property_dialog
      @property_dialog.close
      @property_dialog = nil
    end
  end
  
  def add_member(member, autoreload=true)
    if m = find_member(member.nick)
      m.username = member.username unless member.username.empty?
      m.address = member.username unless member.address.empty?
      m.o = member.o
      m.v = member.v
    else
      @members << member
    end
    if autoreload
      sort_members
      reload_members
    end
  end
  
  def remove_member(nick, autoreload=true)
    @members.delete_if {|m| m.nick.downcase == nick.downcase }
    reload_members if autoreload
    @op_queue.delete_if {|i| i.downcase == nick.downcase }
  end
  
  def rename_member(nick, tonick)
    m = find_member(nick)
    return unless m
    remove_member(tonick, false)

    index = @op_queue.index {|i| i.downcase == nick.downcase }
    if index
      @op_queue.delete_at(index)
      @op_queue << tonick
    end

    remove_member(nick, false)
    m.nick = tonick
    add_member(m)
  end
  
  def update_member(nick, username, address, o=nil, v=nil)
    m = find_member(nick)
    return unless m
    m.username = username
    m.address = address
    m.o = o if o != nil
    m.v = v if v != nil
  end
  
  def change_member_op(nick, type, value)
    m = find_member(nick)
    return unless m
    case type
    when :o; m.o = value
    when :v; m.v = value
    end
    sort_members
    reload_members
    
    if type == :o && value
      @op_queue.delete_if {|i| i.downcase == nick.downcase }
    end
  end
  
  def clear_members
    @members.clear
    reload_members
  end
  
  def find_member(nick)
    @members.find {|m| m.nick.downcase == nick.downcase }
  end
  
  def count_members
    @members.size
  end
  
  def reload_members
    if @unit.world.selected == self
      @unit.world.member_list.reloadData
    end
  end
  
  def sort_members
    @members.sort! do |a,b|
      if unit.mynick == a.nick
        -1
      elsif unit.mynick == b.nick
        1
      elsif a.o != b.o
        a.o ? -1 : 1
      elsif a.v != b.v
        a.v ? -1 : 1
      else
        a.nick.downcase <=> b.nick.downcase
      end
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
    unless @op_queue.find {|i| i.downcase == nick.downcase }
      @op_queue << nick.dup
    end
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
      @cached_label = NSString.stringWithString(name)
    end
    @cached_label
  end
  
  # table
  
  def numberOfRowsInTableView(sender)
    @members.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    m = @members[row]
    head = if m.o
      '@'
    elsif m.v
      '+'
    else
      ''
    end
    head + m.nick
  end
  
  # timer
  
  def on_timer
    if active?
      @op_wait -= 1 if @op_wait > 0
      if @unit.ready_to_send? && @op_wait == 0 && @op_queue.size > 0
        ary = @op_queue[0..2]
        @op_queue[0..2] = nil
        ary = ary.select {|i| m = find_member(i); m && !m.o }
        unless ary.empty?
          @op_wait = ary.size * 3 + 1
          @unit.change_op(self, ary, :o, true)
        end
      end
    end
  end
  
  def preferences_changed
  end
  
  private
  
  def update_channel_title
    @unit.update_channel_title(self)
  end
end
