// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface PasteSheet : SheetBase

@property (nonatomic) NSString* nick;
@property (nonatomic) int uid;
@property (nonatomic) int cid;
@property (nonatomic) NSString* originalText;
@property (nonatomic) NSString* command;
@property (nonatomic) NSSize size;
@property (nonatomic) BOOL editMode;
@property (nonatomic, readonly) BOOL isShortText;

@property (nonatomic) IBOutlet NSTextView* bodyText;
@property (nonatomic) IBOutlet NSButton* sendInChannelButton;
@property (nonatomic) IBOutlet NSPopUpButton* commandPopup;

- (void)start;

- (void)sendInChannel:(id)sender;

@end


@interface NSObject (PasteSheetDelegate)
- (void)pasteSheet:(PasteSheet*)sender onPasteText:(NSString*)text;
- (void)pasteSheetOnCancel:(PasteSheet*)sender;
- (void)pasteSheetWillClose:(PasteSheet*)sender;
@end
