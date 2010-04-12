// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "GistClient.h"


@interface PasteSheet : SheetBase
{
	NSString* nick;
	int uid;
	int cid;
	NSString* originalText;
	NSString* syntax;
	NSString* command;
	NSSize size;
	BOOL editMode;
	BOOL isShortText;
	
	GistClient* gist;
	
	IBOutlet NSTextView* bodyText;
	IBOutlet NSButton* pasteOnlineButton;
	IBOutlet NSButton* sendInChannelButton;
	IBOutlet NSPopUpButton* syntaxPopup;
	IBOutlet NSPopUpButton* commandPopup;
	IBOutlet NSProgressIndicator* uploadIndicator;
	IBOutlet NSTextField* errorLabel;
}

@property (nonatomic, retain) NSString* nick;
@property (nonatomic, assign) int uid;
@property (nonatomic, assign) int cid;
@property (nonatomic, retain) NSString* originalText;
@property (nonatomic, retain) NSString* syntax;
@property (nonatomic, retain) NSString* command;
@property (nonatomic, assign) NSSize size;
@property (nonatomic, assign) BOOL editMode;
@property (nonatomic, readonly) BOOL isShortText;

- (void)start;

- (void)pasteOnline:(id)sender;
- (void)sendInChannel:(id)sender;

@end


@interface NSObject (PasteSheetDelegate)
- (void)pasteSheet:(PasteSheet*)sender onPasteText:(NSString*)text;
- (void)pasteSheet:(PasteSheet*)sender onPasteURL:(NSString*)url;
- (void)pasteSheetOnCancel:(PasteSheet*)sender;
- (void)pasteSheetWillClose:(PasteSheet*)sender;
@end
