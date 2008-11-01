# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'pathname'
require 'viewtheme'
require 'fileutils'

class PreferenceDialog < NSObject
  include DialogHelper
  attr_accessor :delegate
  ib_outlet :window, :dcc_myaddress_caption, :sound_table
  ib_mapped_outlet :keyword_words, :keyword_dislike_words, :keyword_whole_line
  ib_outlet :keyword_dislike_words_caption
  ib_mapped_int_outlet :dcc_address_detection_method
  ib_mapped_outlet :dcc_myaddress
  ib_mapped_int_outlet :dcc_first_port, :dcc_last_port
  ib_mapped_outlet :dcc_auto_receive
  ib_mapped_int_outlet :general_tab_action
  ib_outlet :hotkey
  ib_mapped_int_outlet :general_main_window_layout
  ib_mapped_outlet :general_connect_on_doubleclick, :general_disconnect_on_doubleclick, :general_join_on_doubleclick, :general_leave_on_doubleclick
  ib_mapped_outlet :general_log_transcript
  ib_outlet :transcript_folder
  ib_mapped_int_outlet :general_max_log_lines
  ib_outlet :theme
  ib_outlet :log_font_text
  
  def initialize
    @prefix = 'preferenceDialog'
  end
  
  def start
    NSBundle.loadNibNamed_owner('PreferenceDialog', self)
    load
    update_myaddress
    update_transcript_folder
    onKeyMatchingMethodChanged(nil)
    onLogTranscriptChanged(nil)
    showFontDescription
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
    NSFontPanel.sharedFontPanel.orderOut(nil)
    @log_dialog.cancel(nil) if @log_dialog
    fire_event('onClose')
  end
  
  def onOk(sender)
    save
    fire_event('onOk', preferences)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  # For now leave this in, but use the `preferences' singleton instead of the outlet.
  # Because enabling/disabling the caption and text color doesn't work that easy through bindings.
  # A few notes:
  # * Add a `?' query method for preferences that are booleans, because code should be beautiful.
  # * Add a callback mechanism for preferences values which would then call this method instead of defining an action in IB.
  #   preferences.keyword.matching_method_bind(self, :onKeyMatchingMethodChanged)
  def onKeyMatchingMethodChanged(sender)
    cond = preferences.keyword.matching_method != Preferences::Keyword::MATCH_EXACT_WORD
    @keyword_dislike_words_caption.setTextColor(cond ? NSColor.controlTextColor : NSColor.disabledControlTextColor)
    @keyword_dislike_words.setTextColor(cond ? NSColor.textColor : NSColor.disabledControlTextColor)
    @keyword_dislike_words.setEditable(cond)
    @keyword_dislike_words.setSelectable(cond)
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
      @log_dialog.setCanCreateDirectories(true)
      path = Pathname.new(preferences.general.transcript_folder.expand_path)
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
    preferences.general.transcript_folder = path.collapse_path
    update_transcript_folder
  end
  
  def update_transcript_folder
    path = Pathname.new(preferences.general.transcript_folder).expand_path
    title = path.basename.to_s
    i = @transcript_folder.itemAtIndex(0)
    i.setTitle(title)
    icon = NSWorkspace.sharedWorkspace.iconForFile(path.to_s)
    icon.setSize(NSSize.new(16,16))
    i.setImage(icon)
  end
  
  def onLogTranscriptChanged(sender)
    state = @general_log_transcript.state == 1
    @transcript_folder.setEnabled(state)
  end
  
  def onOpenThemePath(sender)
    path = Pathname.new(ViewTheme.USER_BASE)
    unless path.exist?
      path.mkpath rescue nil
    end
    files = Dir.glob(path.to_s + '/*') rescue []
    if files.empty?
      # copy sample themes
      FileUtils.cp(Dir.glob(ViewTheme.RESOURCE_BASE + '/Sample.*'), ViewTheme.USER_BASE) rescue nil
    end
    NSWorkspace.sharedWorkspace.openFile(path.to_s)
  end
  
  def onSelectFont(sender)
    fm = NSFontManager.sharedFontManager
    fm.setSelectedFont_isMultiple(@log_font, false)
    fm.orderFrontFontPanel(self)
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
  
  def changeFont(sender)
    @log_font = sender.convertFont(@log_font)
    showFontDescription
  end
  
  def showFontDescription
    s = "#{@log_font.displayName} #{@log_font.pointSize.to_i}pt."
    @log_font_text.setStringValue(s)
  end
  
  private
  
  def load
    load_mapped_outlets(preferences, true)
    @sound = preferences.sound
    load_theme
    
    @log_font = NSFont.fontWithName_size(preferences.theme.log_font_name, preferences.theme.log_font_size)
    
    if preferences.general.use_hotkey
      @hotkey.setKeyCode_modifierFlags(preferences.general.hotkey_key_code, preferences.general.hotkey_modifier_flags)
    else
      @hotkey.clearKey
    end
  end
  
  def save
    save_mapped_outlets(preferences, true)
    preferences.keyword.words.delete_if {|i| i.empty?}
    preferences.keyword.words = preferences.keyword.words.sort_by {|i| i.downcase}
    preferences.keyword.words.uniq!
    preferences.keyword.dislike_words.delete_if {|i| i.empty?}
    preferences.keyword.dislike_words = preferences.keyword.dislike_words.sort_by {|i| i.downcase}
    preferences.keyword.dislike_words.uniq!
    preferences.dcc.last_port = preferences.dcc.first_port if preferences.dcc.last_port < preferences.dcc.first_port
    #preferences.assign(@sound) # FIXME: Need to check what this exacty did.
    save_theme
    preferences.general.max_log_lines = 100 if preferences.general.max_log_lines <= 100
    
    preferences.theme.log_font_name = @log_font.fontName
    preferences.theme.log_font_size = @log_font.pointSize
    
    if @hotkey.valid?
      preferences.general.use_hotkey = true
      preferences.general.hotkey_key_code = @hotkey.keyCode
      preferences.general.hotkey_modifier_flags = @hotkey.modifierFlags
    else
      preferences.general.use_hotkey = false
    end
  end
  
  def load_theme
    @theme.removeAllItems
    @theme.addItemWithTitle('Default')
    @theme.itemAtIndex(0).setTag(0)
    
    [ViewTheme.RESOURCE_BASE, ViewTheme.USER_BASE].each_with_index do |base,tag|
      files = Pathname.glob(base + '/*.css') + Pathname.glob(base + '/*.yaml')
      files.map! {|i| i.basename('.*').to_s}
      files.delete('Sample') if tag == 0
      files.uniq!
      files.sort! {|a,b| a.casecmp(b)}
      unless files.empty?
        @theme.menu.addItem(NSMenuItem.separatorItem)
        count = @theme.numberOfItems
        files.each_with_index do |f,n|
          item = NSMenuItem.alloc.initWithTitle_action_keyEquivalent(f, nil, '')
          item.setTag(tag)
          @theme.menu.addItem(item)
        end
      end
    end
    
    kind, name = ViewTheme.extract_name(preferences.theme.name)
    target_tag = kind == 'resource' ? 0 : 1
    
    count = @theme.numberOfItems
    (0...count).each do |n|
      i = @theme.itemAtIndex(n)
      if i.tag == target_tag && i.title.to_s == name
        @theme.selectItemAtIndex(n)
        break
      end
    end
  end
  
  def save_theme
    sel = @theme.selectedItem
    fname = sel.title.to_s
    if sel.tag == 0
      preferences.theme.name = ViewTheme.resource_filename(fname)
    else
      preferences.theme.name = ViewTheme.user_filename(fname)
    end
  end
  
  def update_myaddress
    cond = @dcc_address_detection_method.selectedItem.tag == Preferences::Dcc::ADDR_DETECT_SPECIFY
    @dcc_myaddress_caption.setTextColor(cond ? NSColor.controlTextColor : NSColor.disabledControlTextColor)
    @dcc_myaddress.setEnabled(cond)
  end
end
