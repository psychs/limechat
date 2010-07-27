// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "OnigRegexp.h"


#define CHAR_SIZE 2

#ifndef NSUTF16LittleEndianStringEncoding
#define NSUTF16LittleEndianStringEncoding (-1811939072)
#endif

#define STRING_ENCODING NSUTF16LittleEndianStringEncoding
#define ONIG_ENCODING ONIG_ENCODING_UTF16_LE


@interface OnigResult (Private)
- (id)initWithRegexp:(OnigRegexp*)expression region:(OnigRegion*)region target:(NSString*)target;
@end


@implementation OnigRegexp

- (id)initWithEntity:(regex_t*)entity expression:(NSString*)expression
{
	self = [super init];
	if (self) {
		_entity = entity;
		_expression = [expression copy];
	}
	return self;
}

- (void)dealloc
{
	if (_entity) onig_free(_entity);
	[_expression release];
	[super dealloc];
}

+ (OnigRegexp*)compile:(NSString*)expression
{
	return [self compile:expression ignorecase:NO multiline:NO extended:NO];
}

+ (OnigRegexp*)compileIgnorecase:(NSString*)expression
{
	return [self compile:expression ignorecase:YES multiline:NO extended:NO];	 
}

+ (OnigRegexp*)compile:(NSString*)expression ignorecase:(BOOL)ignorecase multiline:(BOOL)multiline
{
	return [self compile:expression ignorecase:ignorecase multiline:multiline extended:NO];	 
}

+ (OnigRegexp*)compile:(NSString*)expression ignorecase:(BOOL)ignorecase multiline:(BOOL)multiline extended:(BOOL)extended
{
	if (!expression) return nil;
	
	OnigOptionType option = ONIG_OPTION_NONE;
	option |= multiline ? ONIG_OPTION_MULTILINE : ONIG_OPTION_SINGLELINE;
	if (ignorecase) option |= ONIG_OPTION_IGNORECASE;
	if (extended) option |= ONIG_OPTION_EXTEND;
	
	OnigErrorInfo err;
	regex_t* entity = 0;
	const UChar* str = (const UChar*)[expression cStringUsingEncoding:STRING_ENCODING];

	int status = onig_new(&entity,
							str,
							str + [expression length] * CHAR_SIZE,
							option,
							ONIG_ENCODING,
							ONIG_SYNTAX_DEFAULT,
							&err);

	if (status == ONIG_NORMAL) {
		return [[[self alloc] initWithEntity:entity expression:expression] autorelease];
	}
	else {
		if (entity) onig_free(entity);
		return nil;
	}
}

- (OnigResult*)search:(NSString*)target
{
	return [self search:target start:0 end:-1];
}

- (OnigResult*)search:(NSString*)target start:(int)start
{
	return [self search:target start:start end:-1];
}

- (OnigResult*)search:(NSString*)target start:(int)start end:(int)end
{
	if (!target) return nil;
	if (end < 0) end = [target length];
	
	OnigRegion* region = onig_region_new();
	const UChar* str = (const UChar*)[target cStringUsingEncoding:STRING_ENCODING];
	
	int status = onig_search(_entity,
								str,
								str + [target length] * CHAR_SIZE,
								str + start * CHAR_SIZE,
								str + end * CHAR_SIZE,
								region,
								ONIG_OPTION_NONE);

	if (status != ONIG_MISMATCH) {
		return [[[OnigResult alloc] initWithRegexp:self region:region target:target] autorelease];
	}
	else {
		onig_region_free(region, 1);
		return nil;
	}
}

- (OnigResult*)search:(NSString*)target range:(NSRange)range
{
	return [self search:target start:range.location end:NSMaxRange(range)];
}

- (OnigResult*)match:(NSString*)target
{
	return [self match:target start:0];
}

- (OnigResult*)match:(NSString*)target start:(int)start
{
	if (!target) return nil;

	OnigRegion* region = onig_region_new();
	const UChar* str = (const UChar*)[target cStringUsingEncoding:STRING_ENCODING];
	
	int status = onig_match(_entity,
								str,
								str + [target length] * CHAR_SIZE,
								str + start * CHAR_SIZE,
								region,
								ONIG_OPTION_NONE);

	if (status != ONIG_MISMATCH) {
		return [[[OnigResult alloc] initWithRegexp:self region:region target:target] autorelease];
	}
	else {
		onig_region_free(region, 1);
		return nil;
	}
}

- (NSString*)expression
{
	return _expression;
}

- (regex_t*)entity
{
	return _entity;
}

@end


@implementation OnigResult

- (id)initWithRegexp:(OnigRegexp*)expression region:(OnigRegion*)region target:(NSString*)target
{
	self = [super init];
	if (self) {
		_expression = [expression retain];
		_region = region;
		_target = [target copy];
	}
	return self;
}

- (void)dealloc
{
	[_expression release];
	if (_region) onig_region_free(_region, 1);
	[_target release];
	[super dealloc];
}

- (NSString*)target
{
	return _target;
}

- (int)size
{
	return [self count];
}

- (int)count
{
	return _region->num_regs;
}

- (NSString*)stringAt:(int)index
{
	return [_target substringWithRange:[self rangeAt:index]];
}

- (NSArray*)strings
{
	NSMutableArray* array = [NSMutableArray array];
	int i, count;
	for (i=0, count=[self count]; i<count; i++) {
		[array addObject:[self stringAt:i]];
	}
	return array;
}

- (NSRange)rangeAt:(int)index
{
	return NSMakeRange([self locationAt:index], [self lengthAt:index]);
}

- (int)locationAt:(int)index
{
	return *(_region->beg + index) / CHAR_SIZE;
}

- (int)lengthAt:(int)index
{
	return (*(_region->end + index) - *(_region->beg + index)) / CHAR_SIZE;	 
}

- (NSString*)body
{
	return [self stringAt:0];
}

- (NSRange)bodyRange
{
	return [self rangeAt:0];
}

- (NSString*)preMatch
{
	return [_target substringToIndex:[self locationAt:0]];
}

- (NSString*)postMatch
{
	return [_target substringFromIndex:[self locationAt:0] + [self lengthAt:0]];
}

- (int)indexForName:(NSString*)name
{
	NSIndexSet* indexes = [self indexesForName:name];
	return indexes ? [indexes firstIndex] : -1;
}

- (NSIndexSet*)indexesForName:(NSString*)name
{
	int len = sizeof(int) * [self count];
	int* buf = alloca(len);
	memset(&buf, 0, len);
	const UChar* str = (const UChar*)[name cStringUsingEncoding:STRING_ENCODING];
	
	int num = onig_name_to_group_numbers([_expression entity], str, str + [name length] * CHAR_SIZE, &buf);
	if (num < 0) return nil;
	
	NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
	int i;
	for (i=0; i<num; i++) {
		[indexes addIndex:*(buf+i)];
	}
	return indexes;
}

- (NSString*)stringForName:(NSString*)name
{
	int n = [self indexForName:name];
	return n < 0 ? nil : [self stringAt:n];
}

- (NSArray*)stringsForName:(NSString*)name
{
	NSIndexSet* indexes = [self indexesForName:name];
	if (!indexes) return nil;
	
	NSMutableArray* array = [NSMutableArray array];
	for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
		[array addObject:[self stringAt:i]];
	}
	return array;
}

@end
