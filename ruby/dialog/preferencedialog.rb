# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'pathname'
require 'viewtheme'
require 'fileutils'

class PreferenceDialog < NSObject
  include DialogHelper
  attr_accessor :delegate
  ib_outlet :window
  ib_outlet :hotkey
  ib_outlet :transcript_folder
  ib_outlet :theme
  ib_outlet :highlightArrayController, :dislikeArrayController, :ignoreArrayController
  ib_outlet :highlightTable, :dislikeTable, :ignoreTable
  
  include Preferences::KVOCallbackHelper
  extend Preferences::StringArrayWrapperHelper
  
  string_array_kvc_wrapper_accessor :highlight_words, 'preferences.keyword.words'
  string_array_kvc_wrapper_accessor :dislike_words, 'preferences.keyword.dislike_words'
  string_array_kvc_wrapper_accessor :ignore_words, 'preferences.keyword.ignore_words'
  
  kvc_accessor :sounds
  kvc_accessor :available_sounds
  kvc_accessor :log_font
  kvc_accessor :dcc_last_port
  kvc_accessor :max_log_lines
  
  def initialize
    @prefix = 'preferenceDialog'
  end
  
  def init
    if super_init
      @available_sounds = preferences.sound.available_sounds
      @sounds = preferences.sound.events_wrapped
      @log_font = NSFont.fontWithName_size(preferences.theme.log_font_name, preferences.theme.log_font_size)
      @dcc_last_port = preferences.dcc.last_port
      @max_log_lines = preferences.general.max_log_lines
      self
    end
  end
  
  def start
    NSBundle.loadNibNamed_owner('PreferenceDialog', self)
    
    load_theme
    update_transcript_folder
    
    preferences.theme.observe(:override_log_font, self)
    
    if preferences.general.use_hotkey?
      @hotkey.setKeyCode_modifierFlags(preferences.general.hotkey_key_code, preferences.general.hotkey_modifier_flags)
    else
      @hotkey.clearKey
    end
    @hotkey.delegate = self
    
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
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  def onLayoutChanged(sender)
    NSApp.delegate.update_layout
  end
  
  def hotkeyUpdated(hotkey)
    if @hotkey.valid?
      preferences.general.use_hotkey = true
      preferences.general.hotkey_key_code = @hotkey.keyCode
      preferences.general.hotkey_modifier_flags = @hotkey.modifierFlags
      NSApp.registerHotKey_modifierFlags(@hotkey.keyCode, @hotkey.modifierFlags)
    else
      preferences.general.use_hotkey = false
      NSApp.unregisterHotKey
    end
  end
  
  # Highlight
  
  def editTable(table)
    row = table.numberOfRows - 1
    table.scrollRowToVisible(row)
    table.editColumn_row_withEvent_select(0, row, nil, true)
  end
  
  def editHighlightWord
    editTable(@highlightTable)
  end
  
  def editDislikeWord
    editTable(@dislikeTable)
  end
  
  def editIgnoreWord
    editTable(@ignoreTable)
  end
  
  def onAddHighlightWord(sender)
    @highlightArrayController.add(nil)
    performSelector_withObject_afterDelay('editHighlightWord', nil, 0)
  end
  
  def onAddDislikeWord(sender)
    @dislikeArrayController.add(nil)
    performSelector_withObject_afterDelay('editDislikeWord', nil, 0)
  end
  
  def onAddIgnoreWord(sender)
    @ignoreArrayController.add(nil)
    performSelector_withObject_afterDelay('editIgnoreWord', nil, 0)
  end
  
  # Validate these values before setting them on the preferences.
  
  def dcc_last_port=(port)
    preferences.dcc.last_port = @dcc_last_port = port
  end
  
  def max_log_lines=(max)
    preferences.general.max_log_lines = @max_log_lines = max.to_i
  end
  
  def validateValue_forKeyPath_error(value, key, error)
    case key
    when 'dcc_last_port'
      value.assign(value[0].to_i < preferences.dcc.first_port.to_i ? preferences.dcc.first_port : value[0])
    when 'max_log_lines'
      value.assign(100) if value[0].to_i <= 100
    end
    true
  end
  
  # Transcript
  
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
  
  # Log Font
  
  def onSelectFont(sender)
    fm = NSFontManager.sharedFontManager
    fm.setSelectedFont_isMultiple(@log_font, false)
    fm.orderFrontFontPanel(self)
  end
  
  def changeFont(sender)
    # use the kvc_accessor setter method, which send the appropriate KVO messages
    self.log_font = sender.convertFont(@log_font)
    preferences.theme.log_font_name = @log_font.fontName
    preferences.theme.log_font_size = @log_font.pointSize
    onLayoutChanged(nil)
  end
  
  # Called when preferences.theme.override_log_font is changed.
  def override_log_font_changed(override)
    onLayoutChanged(nil)
  end
  
  # Theme
  
  def onChangedTheme(sender)
    save_theme
    onLayoutChanged(nil)
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
  
  private
  
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
end
