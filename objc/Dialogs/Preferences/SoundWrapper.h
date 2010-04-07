// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>

#define EMPTY_SOUND		@"-"


@interface SoundWrapper : NSObject
{
	NSString* displayName;
	NSString* sound;
	SEL saveSelector;
}

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, retain) NSString* sound;
@property (nonatomic, readonly) SEL saveSelector;

- (id)initWithDisplayName:(NSString*)aDisplayName sound:(NSString*)aSound saveSelector:(SEL)aSaveSelector;

@end
