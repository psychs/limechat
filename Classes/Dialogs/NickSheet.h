// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface NickSheet : SheetBase

@property (nonatomic) int uid;

@property (nonatomic) IBOutlet NSTextField* currentText;
@property (nonatomic) IBOutlet NSTextField* nextText;

- (void)start:(NSString*)nick;

@end


@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)nick;
- (void)nickSheetWillClose:(NickSheet*)sender;
@end
