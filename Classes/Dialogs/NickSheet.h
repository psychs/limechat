// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface NickSheet : SheetBase
{
    IBOutlet NSTextField* currentText;
    IBOutlet NSTextField* newText;
}

@property (nonatomic) int uid;

- (void)start:(NSString*)nick;

@end


@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)nick;
- (void)nickSheetWillClose:(NickSheet*)sender;
@end
