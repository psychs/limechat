// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCPrefix.h"


@implementation IRCPrefix

- (id)init
{
    self = [super init];
    if (self) {
        _raw = @"";
        _nick = @"";
        _user = @"";
        _address = @"";
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.raw forKey:@"raw"];
    [aCoder encodeObject:self.nick forKey:@"nick"];
    [aCoder encodeObject:self.user forKey:@"user"];
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeObject:@(self.isServer) forKey:@"isServer"];

}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.raw = [aDecoder decodeObjectForKey:@"raw"];
        self.nick = [aDecoder decodeObjectForKey:@"nick"];
        self.user = [aDecoder decodeObjectForKey:@"user"];
        self.address = [aDecoder decodeObjectForKey:@"address"];
        self.isServer = [[aDecoder decodeObjectForKey:@"isServer"] boolValue];

        
    }
    return self;
}
@end
