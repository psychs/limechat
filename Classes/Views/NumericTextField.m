// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NumericTextField.h"


@implementation NumericTextField

- (void)setIntValue:(int)value
{
    [self setStringValue:[NSString stringWithFormat:@"%d", value]];
}

- (void)setIntegerValue:(NSInteger)value
{
    [self setStringValue:[NSString stringWithFormat:@"%ld", value]];
}

@end
