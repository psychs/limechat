require File.expand_path('../../test_helper', __FILE__)
require 'model/preferences'

describe "Preferences" do
  it "should be a singleton" do
    Preferences.should.include Singleton
    Preferences.instance.should.be.instance_of Preferences
  end
  
  it "should have defined a shortcut method on Kernel" do
    preferences.should.be Preferences.instance
  end
  
  it "should have instances of all section classes" do
    %w{ keyword dcc general sound theme }.each do |section|
      preferences.send(section).class.name.should == "Preferences::#{section.capitalize}"
    end
  end
end

class TestDefaults < Preferences::General
  defaults_accessor :an_option, true
end
Preferences.register_default_values!

describe "Preferences::AbstractPreferencesSection" do
  it "should know the key in the prefs based on it's section class name" do
    TestDefaults.section_defaults_key.should == :TestDefaults
  end
  
  it "should should add default values to the Preferences.default_values" do
    TestDefaults.section_default_values.should == Preferences.default_values[:TestDefaults]
  end
  
  it "should register user defaults with ::defaults_accessor" do
    prefs = TestDefaults.new
    Preferences.default_values[:TestDefaults][:an_option].should == true
    prefs.an_option.should == true
    prefs.an_option = false
    prefs.an_option.should == false
  end
end

describe "Preferences sections" do
  it "should include the `general' preferences" do
    preferences.general.should.be.instance_of Preferences::General
  end
  
  %w{ General Keyword Dcc Sound }.each do |section|
    it "should have set the correct default values for the `#{section}' section" do
      klass = Preferences.const_get(section)
      klass.section_default_values.should.not.be.empty
      klass.section_default_values.each do |attr, value|
        preferences.send(section.downcase).send(attr).should == value
      end
    end
  end
end