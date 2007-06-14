# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class IRCChannel < OSX::NSObject
  include OSX
  attr_accessor :unit, :id, :topic, :names_init
  attr_accessor :log
  attr_reader :config, :members, :mode
  attr_writer :op
  attr_accessor :property_dialog
  attr_accessor :keyword, :unread, :newtalk
  
  def initialize
    @topic = ''
    @members = []
    @mode = ChannelMode.new
    @op = false
    @active = false
    @names_init = false
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
    reload_members
  end
  
  def deactivate
    @active = false
    @members.clear
    @op = false
    @mode.clear
    reload_members
  end
  
  def close_dialog
    if @property_dialog
      @property_dialog.close
      @property_dialog = nil
    end
  end
  
  def add_member(member, autoreload=true)
    remove_member(member.nick) if find_member(member.nick)
    @members << member
    if autoreload
      sort_members
      reload_members
    end
  end
  
  def remove_member(nick)
    @members.delete_if {|m| m.nick.downcase == nick.downcase }
    reload_members
  end
  
  def rename_member(nick, tonick)
    m = find_member(nick)
    return if !m
    remove_member(tonick)
    m.nick = tonick
    sort_members
    reload_members
  end
  
  def change_member_op(nick, type, value)
    m = find_member(nick)
    return if !m
    case type
    when :o; m.o = value
    when :v; m.v = value
    end
    sort_members
    reload_members
  end
  
  def clear_members
    @members.clear
  end
  
  def find_member(nick)
    @members.find {|m| m.nick.downcase == nick.downcase }
  end
  
  def count_members
    @members.length
  end
  
  def reload_members
    if @unit.world.selected == self
      @unit.world.member_list.reloadData
    end
  end
  
  def sort_members
    @members.sort! {|a,b| a.nick.downcase <=> b.nick.downcase }
  end
  
  # model
  
  def number_of_children
    0
  end

  def child_at(index)
    nil
  end

  def label
    name
  end
  
  # table
  
  def numberOfRowsInTableView(sender)
    @members.length
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
  
  
  private
  
  def update_channel_title
    @unit.update_channel_title(self)
  end
end
