// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "GistClient.h"


@interface PasteSheet : SheetBase
{
    IBOutlet NSTextView* bodyText;
    IBOutlet NSButton* pasteOnlineButton;
    IBOutlet NSButton* sendInChannelButton;
    IBOutlet NSPopUpButton* syntaxPopup;
    IBOutlet NSPopUpButton* commandPopup;
    IBOutlet NSProgressIndicator* uploadIndicator;
    IBOutlet NSTextField* errorLabel;
}

@property (nonatomic, strong) NSString* nick;
@property (nonatomic) int uid;
@property (nonatomic) int cid;
@property (nonatomic, strong) NSString* originalText;
@property (nonatomic, strong) NSString* syntax;
@property (nonatomic, strong) NSString* command;
@property (nonatomic) NSSize size;
@property (nonatomic) BOOL editMode;
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
