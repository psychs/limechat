# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ServerDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :window
  attr_accessor :delegate, :prefix
  attr_reader :uid
  ib_mapped_outlet :nameText, :hostCombo, :passwordText, :nickText, :usernameText, :realnameText, :encodingCombo, :auto_connectCheck
  ib_mapped_int_outlet :portText
  ib_outlet :leaveCommentText, :userinfoText, :invisibleCheck, :loosenNickLengthCheck, :nickLengthText
  ib_outlet :channelsTable, :addButton, :editButton, :upButton, :downButton
  ib_outlet :okButton
  
  def initialize
    @prefix = 'serverDialog'
  end
  
  def config
    @c
  end
  
  def start(config, uid)
    @c = config
    @uid = uid
    NSBundle.loadNibNamed_owner('ServerDialog', self)
    @channelsTable.setTarget(self)
    @channelsTable.setDoubleAction('tableView_doubleClicked:')
    @window.setTitle("New Server") if uid < 0
    load
    update_connection_page
    update_channels_page
    show
  end
  
  def show
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    save
    fire_event('onOk', @c)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def load
    load_mapped_outlets(@c)
  end
  
  def save
    save_mapped_outlets(@c)
  end
  
  def controlTextDidChange(n)
    update_connection_page
  end
  
  def update_connection_page
    name = @nameText.stringValue.to_s
    host = @hostCombo.stringValue.to_s
    port = @portText.stringValue.to_s
    nick = @nickText.stringValue.to_s
    username = @usernameText.stringValue.to_s
    realname = @realnameText.stringValue.to_s
    @okButton.setEnabled(!name.empty? && !host.empty? && port.to_i > 0 && !nick.empty? && !username.empty? && !realname.empty?)
  end
  
  def update_channels_page
    t = @channelsTable
    sel = t.selectedRows[0]
    unless sel
      @editButton.setEnabled(false)
      @upButton.setEnabled(false)
      @downButton.setEnabled(false)
    else
      @editButton.setEnabled(true)
      if sel == 0
        @upButton.setEnabled(false)
        @downButton.setEnabled(true)
      elsif sel == @c.channels.length - 1
        @upButton.setEnabled(true)
        @downButton.setEnabled(false)
      else
        @upButton.setEnabled(true)
        @downButton.setEnabled(true)
      end
    end
  end
  
  def reload_table
    @channelsTable.reloadData
  end
  
  def numberOfRowsInTableView(sender)
    @c.channels.length
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :name; i.name
    when :pass; i.password
    when :mode; i.mode
    when :topic; i.topic
    when :join; i.auto_join
    when :console; i.console
    when :highlight; i.keyword
    when :unread; i.unread
    end
  end
  
  def tableView_setObjectValue_forTableColumn_row(sender, obj, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :join; i.auto_join = obj.intValue != 0
    when :console; i.console = obj.intValue != 0
    when :highlight; i.keyword = obj.intValue != 0
    when :unread; i.unread = obj.intValue != 0
    end
  end
  
  def tableViewSelectionDidChange(n)
    update_channels_page
  end
  
  def tableView_doubleClicked(sender)
    onEdit(sender)
  end
  
  def onAdd(sender)
    puts 'add'
  end
  
  def onEdit(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    puts 'edit'
  end
  
  def onUp(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    return if sel == 0
    i = @c.channels.delete_at(sel)
    sel -= 1
    @c.channels.insert(sel, i)
    @channelsTable.select(sel)
    reload_table
  end
  
  def onDown(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    return if sel == @c.channels.length - 1
    i = @c.channels.delete_at(sel)
    sel += 1
    @c.channels.insert(sel, i)
    @channelsTable.select(sel)
    reload_table
  end
end

=begin
#import <Cocoa/Cocoa.h>

#define TableRowType @"row"
#define TableRowTypes [NSArray arrayWithObjects:@"row",nil]

@interface AppController : NSObject {

	IBOutlet id sampleTableView;

	NSMutableArray *tableArray;
}
-(void)awakeFromNib;
-(BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
-(BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
@end

@implementation AppController

-(void)awakeFromNib{
	[sampleTableView registerForDraggedTypes:TableRowTypes];
}

-(BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
	[pboard declareTypes:TableRowTypes owner:self];
	[pboard setPropertyList:rows forType:TableRowType];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op{
	NSPasteboard *pboard=[info draggingPasteboard];

	if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TableRowTypes] != nil) {
		return NSDragOperationGeneric;
	} else {
		return NSDragOperationNone;
	}
}

-(BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op{
	NSPasteboard *pboard=[info draggingPasteboard];
	NSEnumerator *e=[[pboard propertyListForType:TableRowType] objectEnumerator];
	NSNumber *number;
	NSMutableArray *upperArray=[NSMutableArray arrayWithArray:[tableArray subarrayWithRange:NSMakeRange(0,row)]];
	NSMutableArray *lowerArray=[NSMutableArray arrayWithArray:[tableArray subarrayWithRange:NSMakeRange(row,([tableArray count] - row))]];
	NSMutableArray *middleArray=[NSMutableArray arrayWithCapacity:0];
	id object;
	int i;

	if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TableRowTypes] != nil) {

		while ((number=[e nextObject]) != nil) {
			object=[tableArray objectAtIndex:[number intValue]];
			[middleArray addObject:object];
			[upperArray removeObject:object];
			[lowerArray removeObject:object];
		}

		[tableArray removeAllObjects];

		[tableArray addObjectsFromArray:upperArray];
		[tableArray addObjectsFromArray:middleArray];
		[tableArray addObjectsFromArray:lowerArray];

		[sampleTableView reloadData];
		[sampleTableView deselectAll:nil];
	
		for (i=[upperArray count];i<([upperArray count] + [middleArray count]);i++) {
			[sampleTableView selectRow:i byExtendingSelection:[sampleTableView allowsMultipleSelection]];
		}

		return YES;
	} else {
		return NO;
	}
}

@end
=end
