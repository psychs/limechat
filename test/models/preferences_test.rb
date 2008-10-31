require File.expand_path('../../test_helper', __FILE__)
require 'controller/preferences'

describe "Preferences" do
  before do
    @preferences = Preferences.new
  end
  
  it "should return the `general' preferences" do
    @preferences.general.should.be.instance_of Preferences::General
  end
  
  it "should have registered the default value for General#confirm_quit" do
    @preferences.general.confirm_quit.to_ruby.should == true
  end
  
  it "should be possible to set a new value for General#confirm_quit" do
    @preferences.general.confirm_quit = false
    @preferences.general.confirm_quit.to_ruby.should == false
  end
end