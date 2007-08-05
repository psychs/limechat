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
    reload_tree
    reload_list
    @tree.expandItem(@w)
    @c.each {|i| @tree.expandItem(i) }
    update
    @window.makeFirstResponder(@edit)
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
    @list.deselectAll(self)
    @list.reloadData
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    @c.each {|u| u.owner = nil; u.channels.each {|c| c.owner = nil }}
    fire_event('onOk', @c)
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
    i = masks.index(s)
    if i
      masks[i] = s
    else
      masks << s
    end
    masks.sort!
    reload_list
    @edit.setStringValue('')
  end
  
  def onOverwrite(sender)
    onAdd(sender)
  end
  
  def onDelete(sender)
    sel = current_sel
    return unless sel
    masks = sel.autoop
    i = @list.selectedRows[0]
    return unless i
    masks.delete_at(i)
    i -= 1 if masks.length <= i
    @list.select(i)
    reload_list
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
    reload_list
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
    sel.autoop[row]
  end
  
  
  def outlineViewSelectionDidChange(n)
    reload_list
  end
  
  def current_sel
    sel = @tree.selectedRows
    sel.empty? ? nil : @tree.itemAtRow(sel[0])
  end
  
  private
  
  def update
  end
end
