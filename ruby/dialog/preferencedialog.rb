# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'pathname'

class PreferenceDialog < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :delegate
  attr_reader :m
  ib_outlet :window, :dcc_myaddress_caption, :sound_table
  ib_mapped_outlet :key_words, :key_dislike_words, :key_whole_line, :key_current_nick
  ib_mapped_int_outlet :dcc_address_detection_method
  ib_mapped_outlet :dcc_myaddress
  ib_mapped_int_outlet :dcc_first_port, :dcc_last_port
  ib_mapped_outlet :gen_confirm_quit
  ib_mapped_int_outlet :gen_tab_action
  ib_mapped_int_outlet :gen_main_window_layout
  ib_mapped_outlet :gen_connect_on_doubleclick, :gen_disconnect_on_doubleclick, :gen_join_on_doubleclick, :gen_leave_on_doubleclick
  ib_mapped_outlet :gen_use_growl
  ib_mapped_outlet :gen_log_transcript
  ib_outlet :transcript_folder
  
  def initialize
    @prefix = 'preferenceDialog'
  end
  
  def start(pref)
    @m = pref
    NSBundle.loadNibNamed_owner('PreferenceDialog', self)
    load
    update_myaddress
    update_transcript_folder
    onLogTranscriptChanged(nil)
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
  
  def windowWillClose(sender)
    @log_dialog.cancel(nil) if @log_dialog
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
  
  def onTranscriptFolderChanged(sender)
    if @transcript_folder.selectedItem.tag == 2
      return if @log_dialog
      @log_dialog = NSOpenPanel.openPanel
      @log_dialog.setCanChooseFiles(false)
      @log_dialog.setCanChooseDirectories(true)
      @log_dialog.setResolvesAliases(true)
      @log_dialog.setAllowsMultipleSelection(false)
      path = Pathname.new(@m.gen.transcript_folder.expand_path)
      dir = path.parent.to_s
      @log_dialog.beginForDirectory_file_types_modelessDelegate_didEndSelector_contextInfo(dir, nil, nil, self, 'transcriptFilePanelDidEnd:returnCode:contextInfo:', nil)
    end
  end
  
  def transcriptFilePanelDidEnd_returnCode_contextInfo(panel, code, info)
    @log_dialog = nil
    @transcript_folder.selectItem(@transcript_folder.itemAtIndex(0))
    return if code != NSOKButton
    path = panel.filenames.to_a[0].to_s
    FileUtils.mkpath(path) rescue nil
    @m.gen.transcript_folder = path.collapse_path
    update_transcript_folder
  end
  
  def update_transcript_folder
    path = @m.gen.transcript_folder.expand_path
    path = Pathname.new(path)
    title = path.basename.to_s
    i = @transcript_folder.itemAtIndex(0)
    i.setTitle(title)
    icon = NSWorkspace.sharedWorkspace.iconForFile(path.to_s)
    icon.setSize(NSSize.new(16,16))
    i.setImage(icon)
  end
  
  def onLogTranscriptChanged(sender)
    state = @gen_log_transcript.state == 1
    @transcript_folder.setEnabled(state)
  end

  # sound table
  
  EMPTY_SOUND = '-'
  SOUNDS = [EMPTY_SOUND, 'Beep', 'Basso', 'Blow', 'Bottle', 'Frog', 'Funk', 'Glass', 'Hero', 'Morse', 'Ping', 'Pop', 'Purr', 'Sosumi', 'Submarine', 'Tink']
  SOUND_TITLES = ['Login', 'Disconnected', 'Highlight', 'New talk', 'Channel text', 'Talk text', 'Kicked', 'Invited',
                  'DCC file receive request', 'DCC file receive success', 'DCC file receive failure', 'DCC file send success', 'DCC file send failure']
  SOUND_ATTRS = [:login, :disconnect, :highlight, :newtalk, :channeltext, :talktext, :kicked, :invited,
                  :file_receive_request, :file_receive_success, :file_receive_failure, :file_send_success, :file_send_failure]
  
  def numberOfRowsInTableView(sender)
    SOUND_TITLES.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    case col.identifier.to_s.to_sym
    when :title
      SOUND_TITLES[row]
    when :sound
      c = col.dataCell
      c.removeAllItems
      SOUNDS.each {|i| c.addItemWithTitle(i) }
      method = SOUND_ATTRS[row]
      value = @sound.__send__(method)
      index = SOUNDS.index(value) || 0
      index
    end
  end

  def tableView_setObjectValue_forTableColumn_row(sender, obj, col, row)
    case col.identifier.to_s.to_sym
    when :sound
      value = SOUNDS[obj.to_i]
      value = '' if value == EMPTY_SOUND
      method = SOUND_ATTRS[row].to_s + '='
      @sound.__send__(method, value)
      SoundPlayer.play(value) unless value.empty?
    end
  end
  
  
  private
  
  def load
    load_mapped_outlets(m, true)
    @sound = m.sound.dup
  end
  
  def save
    save_mapped_outlets(m, true)
    m.key.words.delete_if {|i| i.empty?}
    m.key.words = m.key.words.sort_by {|i| i.downcase}
    m.key.words.uniq!
    m.key.dislike_words.delete_if {|i| i.empty?}
    m.key.dislike_words = m.key.dislike_words.sort_by {|i| i.downcase}
    m.key.dislike_words.uniq!
    m.dcc.last_port = m.dcc.first_port if m.dcc.last_port < m.dcc.first_port
    m.sound.assign(@sound)
  end
  
  def update_myaddress
    cond = @dcc_address_detection_method.selectedItem.tag == Preferences::Dcc::ADDR_DETECT_SPECIFY
    @dcc_myaddress_caption.setTextColor(cond ? NSColor.textColor : NSColor.disabledControlTextColor)
    @dcc_myaddress.setEnabled(cond)
  end
end
