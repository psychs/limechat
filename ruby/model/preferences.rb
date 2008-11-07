# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'
require 'userdefaultsaccess'
require 'abstract_preferences'

class Preferences
  AbstractPreferencesSection = AbstractPreferencesNamespace
  
  class Keyword < AbstractPreferencesSection
    string_array_defaults_accessor :words, [], 'HighlightWordWrapper'
    string_array_defaults_accessor :dislike_words, [], 'DislikeWordWrapper'
    defaults_accessor :whole_line, false
    defaults_accessor :current_nick, true
    
    MATCH_PARTIAL = 0
    MATCH_EXACT_WORD = 1
    defaults_accessor :matching_method, MATCH_PARTIAL
    
    string_array_defaults_accessor :ignore_words, [], 'IgnoreWordWrapper'
  end
  
  class Dcc < AbstractPreferencesSection
    defaults_accessor :first_port, 1096
    defaults_accessor :last_port, 1115
    defaults_accessor :myaddress, ''
    defaults_accessor :auto_receive, false
    
    ADDR_DETECT_JOIN = 2
    ADDR_DETECT_NIC = 1
    ADDR_DETECT_SPECIFY = 0
    defaults_accessor :address_detection_method, ADDR_DETECT_JOIN
  end
  
  class General < AbstractPreferencesSection
    TAB_COMPLETE_NICK = 0
    TAB_UNREAD = 1
    TAB_NONE = 100
    defaults_accessor :tab_action, TAB_COMPLETE_NICK
    
    LAYOUT_2_COLUMNS = 0
    LAYOUT_3_COLUMNS = 1
    defaults_accessor :main_window_layout, LAYOUT_2_COLUMNS
    
    defaults_accessor :confirm_quit, true
    
    defaults_accessor :use_hotkey, false
    defaults_accessor :hotkey_key_code, 0
    defaults_accessor :hotkey_modifier_flags, 0
    
    defaults_accessor :connect_on_doubleclick, false
    defaults_accessor :disconnect_on_doubleclick, false
    defaults_accessor :join_on_doubleclick, true
    defaults_accessor :leave_on_doubleclick, false
    
    defaults_accessor :use_growl, true
    defaults_accessor :stop_growl_on_active, true
    
    defaults_accessor :log_transcript, false
    defaults_accessor :transcript_folder, '~/Documents/LimeChat Transcripts'
    defaults_accessor :max_log_lines, 300
    
    defaults_accessor :paste_syntax, (LanguageSupport.primary_language == 'ja' ? 'notice' : 'privmsg')
  end
  
  class Sound < AbstractPreferencesSection
    EMPTY_SOUND = '-'
    SOUNDS = [EMPTY_SOUND, 'Beep', 'Basso', 'Blow', 'Bottle', 'Frog', 'Funk', 'Glass', 'Hero', 'Morse', 'Ping', 'Pop', 'Purr', 'Sosumi', 'Submarine', 'Tink']
    
    EVENTS = [
      [:login, 'Login'],
      [:disconnect, 'Disconnected'],
      [:highlight, 'Highlight'],
      [:newtalk, 'New talk'],
      [:kicked, 'Kicked'],
      [:invited, 'Invited'],
      [:channeltext, 'Channel text'],
      [:talktext, 'Talk text'],
      [:file_receive_request, 'DCC file receive request'],
      [:file_receive_success, 'DCC file receive success'],
      [:file_receive_failure, 'DCC file receive failure'],
      [:file_send_success, 'DCC file send success'],
      [:file_send_failure, 'DCC file send failure']
    ]
    
    EVENTS.map { |e| e.first }.each { |attr| defaults_accessor attr, '' }
    
    def available_sounds
      SOUNDS
    end
    
    def events_wrapped
      EVENTS.map do |name, display_name|
        SoundWrapper.alloc.initWithName_displayName_sound(name, display_name, send(name))
      end
    end
    
    class SoundWrapper < OSX::NSObject
      kvc_accessor :display_name, :sound
      
      def initWithName_displayName_sound(name, display_name, sound)
        if init
          @name, @display_name, @sound = name, display_name, sound
          self
        end
      end
      
      def sound
        @sound.empty? ? Preferences::Sound::EMPTY_SOUND : @sound
      end
      
      def sound=(sound)
        @sound = sound
        preferences.sound.send("#{@name}=", (@sound == Preferences::Sound::EMPTY_SOUND ? '' : @sound))
      end
    end
  end
  
  class Theme < AbstractPreferencesSection
    defaults_accessor :name, 'resource:Default'
    defaults_accessor :override_log_font, false
    defaults_accessor :log_font_name, 'Lucida Grande'
    defaults_accessor :log_font_size, 12
    defaults_accessor :override_nick_format, false
    defaults_accessor :nick_format, '%n: '
    defaults_accessor :override_timestamp_format, false
    defaults_accessor :timestamp_format, '%H:%M'
  end
  
  %w{ dcc general keyword sound theme }.each do |section|
    class_eval "def #{section}; #{section.capitalize}.instance; end"
  end
  
  include UserDefaultsAccess
  
  def save
    sync
  end
  
  def load_world
    read_defaults('world')
  end
  
  def save_world(c)
    write_defaults('world', c)
    sync
  end
  
  def load_window(key)
    read_defaults(key)
  end
  
  def save_window(key, value)
    write_defaults(key, value)
    sync
  end
  
  private
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  # And register the defaults
  register_default_values!
end

module Kernel
  # A shortcut method for easy access anywhere to the shared user defaults
  def preferences
    Preferences.instance
  end
end