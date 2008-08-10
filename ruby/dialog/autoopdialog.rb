# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'config.rb'

class AutoOpDialog < NSObject
  include DialogHelper  
  attr_accessor :delegate, :prefix
  ib_outlet :window, :tree, :list, :edit, :addButton, :overwriteButton, :deleteButton
  
  def initialize
    @prefix = 'autoOpDialog'
  end
  
  def start(conf)
    @w = ModelTreeItem.config_to_item(conf)
    @c = @w.units
    @sel = @w
    NSBundle.loadNibNamed_owner('AutoOpDialog', self)
    @edit.setFocusRingType(NSFocusRingTypeNone)
    @window.key_delegate = self
    @tree.key_delegate = self
    @list.key_delegate = self
    reload_tree
    reload_list
    @tree.expandItem(@w)
    @c.each {|i| @tree.expandItem(i) }
    @window.makeFirstResponder(@edit)
    update_buttons
    show
  end
  
  def show
    @window.center unless @window.isVisible
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def select_item(uid, chname=nil)
    u = @c.find {|i| i.id == uid }
    if u
      if chname
        c = u.channels.find {|i| i.name == chname }
        if c
          @tree.select(@tree.rowForItem(c))
          return
        end
      end
      @tree.select(@tree.rowForItem(u))
    end
  end
  
  def set_mask(str)
    @edit.setStringValue(str)
    update_buttons
  end
  
  def add_masks(ary)
    masks = @sel.autoop
    ary.each do |s|
      next if s.empty?
      i = masks.index(s)
      next if i
      masks << s
    end
    masks.sort!
    reload_list
    update_buttons
  end
  
  def reload_tree
    @tree.reloadData
  end
  
  def reload_list
    @list.reloadData
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
=begin
    s = @edit.stringValue.to_s
    unless s.empty?
      s = @edit.stringValue.to_s
      unless s.empty?
        unless @sel.autoop.index(s)
          onAdd(sender)
          return
        end
      end
    end
=end
    
    fire_event('onOk', ModelTreeItem.item_to_config(@w))
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onAdd(sender)
    s = @edit.stringValue.to_s
    return if s.empty?
    masks = @sel.autoop
    i = masks.index(s)
    return if i
    masks << s
    masks.sort!
    reload_list
    i = masks.index(s)
    @list.select(i)
    @edit.setStringValue('')
  end
  
  def onOverwrite(sender)
    s = @edit.stringValue.to_s
    return if s.empty?
    masks = @sel.autoop
    i = masks.index(s)
    return if i
    i = @list.selectedRows[0]
    return unless i
    masks[i] = s
    masks.sort!
    reload_list
    i = masks.index(s)
    @list.select(i)
    @edit.setStringValue('')
  end
  
  def onDelete(sender)
    i = @list.selectedRows[0]
    return unless i
    masks = @sel.autoop
    masks.delete_at(i)
    i -= 1 if masks.size <= i
    if i >= 0
      @list.select(i)
    else
      @edit.focus
    end
    reload_list
  end
  
  
  # window
  
  def dialogWindow_moveDown
    i = @tree.selectedRows[0]
    @tree.select(i+1) if i
    @edit.focus
  end
  
  def dialogWindow_moveUp
    i = @tree.selectedRows[0]
    @tree.select(i-1) if i && i > 0
    @edit.focus
  end
  
  
  # tree
  
  def outlineView_numberOfChildrenOfItem(sender, item)
    case item
      when nil; 1
      when WorldTreeItem; item.units.size
      when UnitTreeItem; item.channels.size
      else 0
    end
  end
  
  def outlineView_isItemExpandable(sender, item)
    case item
      when WorldTreeItem; item.units.size > 0
      when UnitTreeItem; item.channels.size > 0
      else false
    end
  end
  
  def outlineView_child_ofItem(sender, index, item)
    case item
      when nil; @w
      when WorldTreeItem; item.units[index]
      when UnitTreeItem; item.channels[index]
      else nil
    end
  end
  
  def outlineView_objectValueForTableColumn_byItem(sender, column, item)
    item.label
  end
  
  def outlineViewSelectionDidChange(notification)
    i = @tree.selectedRows[0]
    @sel = i ? @tree.itemAtRow(i) : nil
    @list.deselectAll(self)
    @list.scrollRowToVisible(0)
    reload_list
  end
  
  def treeView_keyDown(e)
    @edit.focus
    @window.sendEvent(e)
  end
  
  
  # table
  
  def numberOfRowsInTableView(sender)
    return 0 unless @sel
    @sel.autoop.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, column, row)
    return '' unless @sel
    s = @sel.autoop[row]
    s || ''
  end
  
  def tableViewSelectionDidChange(n)
    i = @list.selectedRows[0]
    if i
      s = @sel.autoop[i]
      @edit.setStringValue(s)
    end
    update_buttons
  end
  
  def listView_moveUp(sender)
    @edit.focus
  end
  
  def listView_delete(sender)
    onDelete(sender)
  end
  
  def listView_keyDown(e)
    @edit.focus
    @window.sendEvent(e)
  end
  
  
  # edit
  
  def control_textView_doCommandBySelector(control, textview, selector)
    return false unless @sel
    case selector
    when 'moveDown:'
      if @sel.autoop.size > 0
        sel = @list.selectedRows[0]
        @list.select(0) unless sel
        @window.makeFirstResponder(@list)
      end
      true
    else
      false
    end
  end
  
  def controlTextDidChange(sender)
    update_buttons
  end
  
  
  private
  
  def update_buttons
    update_addButton
    update_overwriteButton
    update_deleteButton
  end
  
  def update_addButton
    s = @edit.stringValue.to_s
    if s.empty?
      @addButton.setEnabled(false)
      return
    end
    i = @sel.autoop.index(s)
    @addButton.setEnabled(!i)
  end
  
  def update_overwriteButton
    s = @edit.stringValue.to_s
    if s.empty?
      @overwriteButton.setEnabled(false)
      return
    end
    i = @sel.autoop.index(s)
    if i
      @overwriteButton.setEnabled(false)
      return
    end
    i = @list.selectedRows[0]
    @overwriteButton.setEnabled(!!i)
  end
  
  def update_deleteButton
    i = @list.selectedRows[0]
    @deleteButton.setEnabled(!!i)
  end
end
