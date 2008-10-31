require File.expand_path('../../test_helper', __FILE__)

describe "AppController" do
  tests AppController
  
  def after_setup
    ib_outlets :member_list => MemberListView.alloc.init,
               :info_split => Splitter.alloc.init
    
    member_list.addTableColumn(NSTableColumn.alloc.init)
    info_split.stubs(:updatePosition)
  end
  
  it "should register the hotkey with NSApp if necessary" do
    preferences.general.stubs(:use_hotkey).returns(true)
    NSApp.expects(:registerHotKey_modifierFlags).with(preferences.general.hotkey_key_code, preferences.general.hotkey_modifier_flags)
    controller.awakeFromNib
  end
  
  it "should instantiate a ViewTheme and MemberListView with the theme from the preferences" do
    preferences.theme.stubs(:name).returns('resource:Default')
    controller.awakeFromNib
    assigns(:view_theme).name.should == preferences.theme.name
    member_list.instance_variable_get(:@theme).instance_variable_get(:@filename).basename.to_s.should == 'Default.yaml'
  end
  
  it "should select the 3 column main window layout if defined in the preferences" do
    preferences.general.stubs(:main_window_layout).returns(Preferences::General::LAYOUT_3_COLUMNS)
    controller.expects(:select_3column_layout).with(true)
    controller.awakeFromNib
  end
end
