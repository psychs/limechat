// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSInteger, ChannelType) {
    CHANNEL_TYPE_CHANNEL,
    CHANNEL_TYPE_TALK,
} ;


@interface IRCChannelConfig : NSObject <NSMutableCopying>

@property (nonatomic) ChannelType type;

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* password;

@property (nonatomic) BOOL autoJoin;
@property (nonatomic) BOOL logToConsole;
@property (nonatomic) BOOL notify;

@property (nonatomic) NSString* mode;
@property (nonatomic) NSString* topic;

@property (nonatomic, readonly) NSMutableArray* autoOp;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValueSavingToKeychain:(BOOL)saveToKeychain;

- (void)deletePasswordsFromKeychain;

@end
