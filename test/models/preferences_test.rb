require File.expand_path('../../test_helper', __FILE__)
require 'controller/preferences'

describe "Preferences" do
  before do
    NSUserDefaults.standardUserDefaults.registerDefaults({
      "pref" => {
        "gen" => {
          "confirm_quit" => false
        }
      }
    })
    
    @preferences = Preferences.new
  end
  
  it "should return the `general' preferences" do
    @preferences.general.should.be.instance_of Preferences::General
  end
  
  it "should return the correct General#confirm_quit value" do
    @preferences.general.confirm_quit.to_ruby.should == false
  end
  
  it "should be possible to set a new value for General#confirm_quit" do
    @preferences.general.confirm_quit = true
    @preferences.general.confirm_quit.to_ruby.should == true
  end
end