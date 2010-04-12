// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface NickSheet : SheetBase
{
	int uid;
	
	IBOutlet NSTextField* currentText;
	IBOutlet NSTextField* newText;
}

@property (nonatomic, assign) int uid;

- (void)start:(NSString*)nick;

@end


@interface NSObject (NickSheetDelegate)
- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)nick;
- (void)nickSheetWillClose:(NickSheet*)sender;
@end
