require File.expand_path('../../test_helper', __FILE__)
require 'model/preferences'

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

describe "Preferences::General" do
  before do
    @preferences = Preferences.new
  end
  
  it "should return the `general' preferences" do
    @preferences.general.should.be.instance_of Preferences::General
  end
  
  it "should have set the correct default values" do
    Preferences::General.section_default_values.should.not.be.empty
    Preferences::General.section_default_values.each do |attr, value|
      @preferences.general.send(attr).should == value
    end
  end
end