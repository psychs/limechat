// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface OtherTheme : NSObject
{
	NSString* fileName;
	NSDictionary* content;
	
	NSString* logNickFormat;
	NSColor* logScrollerMarkColor;
	NSColor* inputTextBgColor;
}

@property (nonatomic, retain) NSString* fileName;

- (void)reload;

@end
