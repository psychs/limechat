// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <RubyCocoa/RBRuntime.h>


int main(int argc, const char* argv[])
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	setenv("HOME", [[@"~/" stringByExpandingTildeInPath] UTF8String], 0);
	[pool drain];
	return RBApplicationMain("rb_main.rb", argc, argv);
}
