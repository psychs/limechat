# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ListDialog < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :delegate, :prefix
  ib_outlet :window, :table, :updateButton, :closeButton
  
  def initialize
    @prefix = 'listDialog'
    @list = []
  end
  
  def start
    NSBundle.loadNibNamed_owner('ListDialog', self)
    @window.makeFirstResponder(@updateButton)
    show
  end
  
  def show
    unless @window.isVisible
      scr = NSScreen.screens[0]
      if scr
        p = scr.visibleFrame.center
        p -= @window.frame.size / 2
        #p += OFFSET_SIZE * (@@place - ROTATE_COUNT/2)
        @window.setFrameOrigin(p)
        #@@place += 1
        #@@place = 0 if @@place >= ROTATE_COUNT
      end
    end
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onClose(sender)
    @window.close
  end
  ib_action :onClose
  
  def onUpdate(sender)
    fire_event('onUpdate')
  end
  ib_action :onUpdate
  
  def onJoin(sender)
    fire_event('onJoin')
  end
  ib_action :onJoin
  
  def update
    #@joinButton.setEnabled(false)
  end
  
  def clear
    @list = []
  end
  
  def add_item(item)
    @list << item
    @table.reloadData
  end
  
  def numberOfRowsInTableView(sender)
    @list.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    m = @list[row]
    case col.identifier
    when 'chname'; m[0]
    when 'number'; m[1].to_s
    else; m[2]
    end
  end
end
