require File.expand_path('../../test_helper', __FILE__)
require 'preferences'

describe "Preferences sections" do
  it "should include the `general' preferences" do
    preferences.general.should.be.instance_of Preferences::General
  end
  
  %w{ General Keyword Dcc Sound }.each do |section|
    it "should have set the correct default values for the `#{section}' section" do
      klass = Preferences.const_get(section)
      section_default_values = Preferences.default_values.select { |key, _| key.include? klass.section_defaults_key }
      section_default_values.should.not.be.empty
      section_default_values.each do |attr, value|
        preferences.send(section.downcase).send(attr.split('.').last).should == value
      end
    end
  end
end

def login_event_wrapper
  preferences.sound.events_wrapped.find { |s| s.display_name == 'Login' }
end

describe "Preferences::Sound" do
  it "should return sounds with their event names wrapped in a KVC compatible class" do
    display_names = Preferences::Sound::EVENTS.map { |e| e.last }
    preferences.sound.events_wrapped.each_with_index do |wrapper, index|
      wrapper.should.be.instance_of Preferences::Sound::SoundWrapper
      wrapper.display_name.should == display_names[index]
    end
  end
  
  it "should return SoundWrapper's initialized with their current `sound' value" do
    preferences.sound.login = 'Beep'
    login_event_wrapper.sound.should == 'Beep'
  end
end

describe "Preferences::Sound::SoundWrapper" do
  it "should update the `sound' value in the preferences which it represents" do
    preferences.sound.login = 'Furr'
    login_event_wrapper.setValue_forKey('Beep', 'sound')
    preferences.sound.login.should == 'Beep'
  end
end