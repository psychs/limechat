# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class PreferenceDialog < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :delegate
  attr_reader :m
  ib_outlet :window, :dcc_myaddress_caption
  ib_mapped_outlet :key_words, :key_dislike_words
  ib_mapped_outlet :dcc_address_detection_method, :dcc_myaddress
  ib_mapped_int_outlet :dcc_first_port, :dcc_last_port
  ib_mapped_outlet :gen_confirm_quit
  
  def initialize
    @prefix = 'preferenceDialog'
  end
  
  def start(pref)
    @m = pref
    NSBundle.loadNibNamed_owner('PreferenceDialog', self)
    load
    update_myaddress
    show
  end
  
  def show
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    save
    fire_event('onOk', m)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onDccAddressDetectionMethodChanged(sender)
    update_myaddress
  end
  
  private
  
  def load
    load_mapped_outlets(m, true)
  end
  
  def save
    save_mapped_outlets(m, true)
    m.key.words.delete_if {|i| i.empty?}
    m.key.words.sort! {|a,b| a.downcase <=> b.downcase}
    m.key.words.uniq!
    m.key.dislike_words.delete_if {|i| i.empty?}
    m.key.dislike_words.sort! {|a,b| a.downcase <=> b.downcase}
    m.key.dislike_words.uniq!
    m.dcc.last_port = m.dcc.first_port if m.dcc.last_port < m.dcc.first_port
  end
  
  def update_myaddress
    cond = @dcc_address_detection_method.selectedItem.tag == Preferences::Dcc::ADDR_DETECT_SPECIFY
    @dcc_myaddress_caption.setTextColor(cond ? NSColor.textColor : NSColor.disabledControlTextColor)
    @dcc_myaddress.setEnabled(cond)
  end
end
