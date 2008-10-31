require File.expand_path('../../test_helper', __FILE__)
require 'controller/preferences'

describe "Preferences" do
  before do
    @preferences = Preferences.new
  end
  
  it "should return the `general' preferences" do
    @preferences.general.should.be.instance_of Preferences::General
  end
end