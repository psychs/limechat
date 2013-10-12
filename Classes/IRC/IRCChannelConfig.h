// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


typedef enum {
    CHANNEL_TYPE_CHANNEL,
    CHANNEL_TYPE_TALK,
} ChannelType;


@interface IRCChannelConfig : NSObject <NSMutableCopying>

@property (nonatomic) ChannelType type;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* password;

@property (nonatomic) BOOL autoJoin;
@property (nonatomic) BOOL logToConsole;
@property (nonatomic) BOOL growl;

@property (nonatomic, strong) NSString* mode;
@property (nonatomic, strong) NSString* topic;

@property (nonatomic, readonly) NSMutableArray* autoOp;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end
