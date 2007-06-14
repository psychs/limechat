// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the same terms as Ruby.

#import "GradientFill.h"

struct GradientColorInfo
{
	float from[4];
	float to[4];
};

static void interpolate(void* info, float const* in, float* out)
{
	const struct GradientColorInfo* ci = (const struct GradientColorInfo*)info;
	const float* from = ci->from;
	const float* to = ci->to;
	float a = in[0];
	
	int i;
	for (i=0; i<4; i++) {
		out[i] = (1.0 - a) * to[i] + a * from[i];
	}
}

@interface GradientFill (Private)
- (void)setBeginColor:(NSColor*)color;
- (void)setEndColor:(NSColor*)color;
@end

@implementation GradientFill

+ (GradientFill*)gradientWithBeginColor:(NSColor*)from endColor:(NSColor*)end
{
	id gradient = [[GradientFill alloc] init];
	[gradient setBeginColor:from];
	[gradient setEndColor:end];
	return gradient;
}

- (void)dealloc
{
	[beginColor release];
	[endColor release];
	[super dealloc];
}

- (void)setBeginColor:(NSColor*)color
{
	beginColor = [color retain];
}

- (void)setEndColor:(NSColor*)color
{
	endColor = [color retain];
}

- (void)fillRect:(NSRect)rect
{
	struct GradientColorInfo ci;
	ci.from[0] = [beginColor redComponent];
	ci.from[1] = [beginColor greenComponent];
	ci.from[2] = [beginColor blueComponent];
	ci.from[3] = [beginColor alphaComponent];
	ci.to[0] = [endColor redComponent];
	ci.to[1] = [endColor greenComponent];
	ci.to[2] = [endColor blueComponent];
	ci.to[3] = [endColor alphaComponent];
	
	struct CGFunctionCallbacks callbacks = {0, interpolate, NULL};
	CGFunctionRef function = CGFunctionCreate(&ci, 1, NULL, 4, NULL, &callbacks);
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
	CGShadingRef shade = CGShadingCreateAxial(cspace, CGPointMake(NSMinX(rect), NSMaxY(rect)), CGPointMake(NSMinX(rect), NSMinY(rect)), function, false, false);
	CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], shade);
	CGShadingRelease(shade);
	CGColorSpaceRelease(cspace);
	CGFunctionRelease(function);
}

@end
