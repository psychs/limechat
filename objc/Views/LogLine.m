// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogLine.h"


@implementation LogLine

@synthesize time;
@synthesize place;
@synthesize nick;
@synthesize body;
@synthesize lineType;
@synthesize memberType;
@synthesize nickInfo;
@synthesize clickInfo;
@synthesize identified;
@synthesize nickColorNumber;

- (id)init
{
	if (self = [super init]) {
		lineType = @"system";
		memberType = @"normal";
	}
	return self;
}

- (void)dealloc
{
	[time release];
	[place release];
	[nick release];
	[body release];
	[lineType release];
	[memberType release];
	[nickInfo release];
	[clickInfo release];
	[super dealloc];
}

@end
