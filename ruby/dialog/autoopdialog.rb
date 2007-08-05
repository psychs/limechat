# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class AutoOpDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :delegate, :prefix
  ib_outlet :window, :tree, :list, :edit, :addButton, :overwriteButton, :deleteButton
  
  def initialize
    @prefix = 'autoOpDialog'
  end
  
  def start(conf)
    @w = conf
    @c = @w.units
    @c.each {|u| u.owner = @w; u.channels.each {|c| c.owner = u }}
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
    s = @edit.stringValue.to_s
    unless s.empty?
      onAdd(sender)
      return
    end
    
    @c.each {|u| u.owner = nil; u.channels.each {|c| c.owner = nil }}
    fire_event('onOk', @w)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onAdd(sender)
    sel = current_sel
    return unless sel
    masks = sel.autoop
    s = @edit.stringValue.to_s
    return if s.empty?
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
    sel = current_sel
    return unless sel
    masks = sel.autoop
    s = @edit.stringValue.to_s
    return if s.empty?
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
    sel = current_sel
    return unless sel
    masks = sel.autoop
    i = @list.selectedRows[0]
    return unless i
    masks.delete_at(i)
    i -= 1 if masks.length <= i
    if i >= 0
      @list.select(i)
    else
      @edit.focus
    end
    reload_list
  end
  
  
  # window
  
  def dialogWindow_moveDown
    sel = current_row
    if sel
      sel += 1
      @tree.select(sel)
    end
    @edit.focus
  end
  
  def dialogWindow_moveUp
    sel = current_row
    if sel
      if sel > 0
        sel -= 1
        @tree.select(sel)
      end
    end
    @edit.focus
  end
  
  
  # tree
  
  def outlineView_numberOfChildrenOfItem(sender, item)
    return 1 unless item
    case item
    when IRCWorldConfig; item.units.length
    when IRCUnitConfig; item.channels.length
    else 0
    end
  end
  
  objc_method :outlineView_isItemExpandable, 'c@:@@'
  def outlineView_isItemExpandable(sender, item)
    case item
    when IRCWorldConfig; item.units.length > 0
    when IRCUnitConfig; item.channels.length > 0
    else false
    end
  end
  
  def outlineView_child_ofItem(sender, index, item)
    return @w unless item
    case item
    when IRCWorldConfig; item.units[index]
    when IRCUnitConfig; item.channels[index]
    else nil
    end
  end
  
  def outlineView_objectValueForTableColumn_byItem(sender, column, item)
    return 'World' if item == @w
    item.name
  end
  
  def outlineViewSelectionDidChange(notification)
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
    sel = current_sel
    return 0 unless sel
    sel.autoop.length
  end
  
  def tableView_objectValueForTableColumn_row(sender, column, row)
    sel = current_sel
    return '' unless sel
    masks = sel.autoop
    if masks.length > 0
      s = sel.autoop[row]
      s ? s : ''
    end
  end
  
  def tableViewSelectionDidChange(n)
    sel = current_sel
    if sel
      masks = sel.autoop
      if masks.length > 0
        sel = @list.selectedRows[0]
        if sel
          s = masks[sel]
          @edit.setStringValue(s)
        end
      end
    end
    #update_buttons
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
  
  objc_method 'control:textView:doCommandBySelector:', 'c@:@@:'
  def control_textView_doCommandBySelector(control, textview, selector)
    case selector
    when 'moveDown:'
      sel = current_sel
      if sel
        masks = sel.autoop
        if masks.length > 0
          sel = @list.selectedRows[0]
          @list.select(0) unless sel
          @window.makeFirstResponder(@list)
        end
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

  def current_sel
    sel = @tree.selectedRows[0]
    sel ? @tree.itemAtRow(sel) : nil
  end
  
  def current_row
    @tree.selectedRows[0]
  end
  
  def update_buttons
    update_addButton
    update_overwriteButton
    update_deleteButton
  end
  
  def update_addButton
    sel = current_sel
    unless sel
      @addButton.setEnabled(false)
      return
    end
    s = @edit.stringValue.to_s
    if s.empty?
      @addButton.setEnabled(false)
      return
    end
    masks = sel.autoop
    i = masks.index(s)
    if i
      @addButton.setEnabled(false)
      return
    end
    @addButton.setEnabled(true)
  end
  
  def update_overwriteButton
    sel = current_sel
    unless sel
      @overwriteButton.setEnabled(false)
      return
    end
    s = @edit.stringValue.to_s
    if s.empty?
      @overwriteButton.setEnabled(false)
      return
    end
    masks = sel.autoop
    i = masks.index(s)
    if i
      @overwriteButton.setEnabled(false)
      return
    end
    i = @list.selectedRows[0]
    @overwriteButton.setEnabled(i != nil)
  end
  
  def update_deleteButton
    i = @list.selectedRows[0]
    @deleteButton.setEnabled(i != nil)
  end
end
