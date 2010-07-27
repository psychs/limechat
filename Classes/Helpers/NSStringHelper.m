// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSStringHelper.h"
#import "UnicodeHelper.h"
#import "OnigRegexp.h"


#define LF	0xa
#define CR	0xd


@implementation NSString (NSStringHelper)

- (const UniChar*)getCharactersBuffer
{
	NSUInteger len = self.length;
	const UniChar* buffer = CFStringGetCharactersPtr((CFStringRef)self);
	if (!buffer) {
		NSMutableData* data = [NSMutableData dataWithLength:len * sizeof(UniChar)];
		if (!data) return NULL;
		[self getCharacters:[data mutableBytes]];
		buffer = [data bytes];
		if (!buffer) return NULL;
	}
	return buffer;
}

- (BOOL)isEqualNoCase:(NSString*)other
{
	return [self caseInsensitiveCompare:other] == NSOrderedSame;
}

- (BOOL)isEmpty
{
	return [self length] == 0;
}

- (BOOL)contains:(NSString*)str
{
	NSRange r = [self rangeOfString:str];
	return r.location != NSNotFound;
}

- (BOOL)containsIgnoringCase:(NSString*)str
{
	NSRange r = [self rangeOfString:str options:NSCaseInsensitiveSearch];
	return r.location != NSNotFound;
}

- (int)findCharacter:(UniChar)c
{
	return [self findCharacter:c start:0];
}

- (int)findCharacter:(UniChar)c start:(int)start
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(c, 1)] options:0 range:NSMakeRange(start, [self length] - start)];
	if (r.location != NSNotFound) {
		return r.location;
	} else {
		return -1;
	}
}

- (int)findString:(NSString*)str
{
	NSRange r = [self rangeOfString:str];
	if (r.location != NSNotFound) {
		return r.location;
	} else {
		return -1;
	}
}

- (NSArray*)split:(NSString*)delimiter
{
	NSMutableArray* ary = [NSMutableArray array];
	int start = 0;
	
	while (start < self.length) {
		NSRange r = [self rangeOfString:delimiter options:0 range:NSMakeRange(start, self.length-start)];
		if (r.location == NSNotFound) break;
		[ary addObject:[self substringWithRange:NSMakeRange(start, r.location - start)]];
		start = NSMaxRange(r);
	}
	
	if (start < self.length) {
		[ary addObject:[self substringWithRange:NSMakeRange(start, self.length - start)]];
	}
	
	return ary;
}

- (NSArray*)splitIntoLines
{
	int len = self.length;
	UniChar buf[len];
	[self getCharacters:buf range:NSMakeRange(0, len)];
	
	NSMutableArray* lines = [NSMutableArray array];
	int start = 0;
	
	for (int i=0; i<len; ++i) {
		UniChar c = buf[i];
		if (c == LF || c == CR) {
			int pos = i;
			if (c == CR && i+1 < len) {
				UniChar next = buf[i+1];
				if (next == LF) {
					++i;
				}
			}
			
			NSString* s = [[NSString alloc] initWithCharacters:buf+start length:pos - start];
			[lines addObject:s];
			[s release];
			
			start = i + 1;
		}
	}
	
	NSString* s = [[NSString alloc] initWithCharacters:buf+start length:len - start];
	[lines addObject:s];
	[s release];
	
	return lines;
}

- (NSString*)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isNumericOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsNumeric(c))) {
			return NO;
		}
	}
	return YES;
}

- (BOOL)isAlphaNumOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsAlphaNum(c))) {
			return NO;
		}
	}
	return YES;
}

BOOL isSurrogate(UniChar c)
{
	return 0xd800 <= c && c <= 0xdfff;
}

BOOL isHighSurrogate(UniChar c)
{
	return 0xd800 <= c && c <= 0xdbff;
}

BOOL isLowSurrogate(UniChar c)
{
	return 0xdc00 <= c && c <= 0xdfff;
}

- (int)firstCharCodePoint
{
	int len = self.length;
	if (len == 0) return -1;
	
	int c = [self characterAtIndex:0];
	if (isHighSurrogate(c)) {
		if (len <= 1) return c;
		int d = [self characterAtIndex:1];
		if (isLowSurrogate(d)) {
			return (c - 0xd800) * 0x400 + (d - 0xdc00) + 0x10000;
		}
		else {
			return -1;
		}
	}
	return c;
}

- (int)lastCharCodePoint
{
	int len = self.length;
	if (len == 0) return -1;
	
	int c = [self characterAtIndex:len-1];
	if (isLowSurrogate(c)) {
		if (len <= 1) return c;
		int d = [self characterAtIndex:len-2];
		if (isHighSurrogate(d)) {
			return (d - 0xd800) * 0x400 + (c - 0xdc00) + 0x10000;
		}
		else {
			return -1;
		}
	}
	return c;
}

int ctoi(unsigned char c)
{
	if ('0' <= c && c <= '9') {
		return c - '0';
	}
	else if ('a' <= c && c <= 'f') {
		return c - 'a' + 10;
	}
	else if ('A' <= c && c <= 'F') {
		return c - 'A' + 10;
	}
	else {
		return 0;
	}
}

BOOL isUnicharDigit(unichar c)
{
	return '0' <= c && c <= '9';
}

- (NSString*)safeUsername
{
	int len = self.length;
	const UniChar* buf = [self getCharactersBuffer];
	
	UniChar dest[len];
	int n = 0;
	
	for (int i=0; i<len; i++) {
		UniChar c = buf[i];
		if (IsWordLetter(c)) {
			dest[n++] = c;
		}
		else {
			dest[n++] = '_';
		}
	}
	
	return [[[NSString alloc] initWithCharacters:dest length:n] autorelease];
}

- (NSString*)safeFileName
{
	NSString* s = [self stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	return [s stringByReplacingOccurrencesOfString:@":" withString:@"_"];
}

- (NSString*)stripEffects
{
	int len = self.length;
	if (len == 0) return self;
	
	int buflen = len * sizeof(unichar);
	
	unichar* src = alloca(buflen);
	[self getCharacters:src];
	
	unichar* buf = alloca(buflen);
	int pos = 0;
	
	for (int i=0; i<len; i++) {
		unichar c = src[i];
		if (c < 0x20) {
			switch (c) {
				case 0x2:
				case 0xf:
				case 0x16:
				case 0x1f:
					break;
				case 0x3:
					//
					// colors
					//
					if (i+1 >= len) continue;
					unichar d = src[i+1];
					if (!isUnicharDigit(d)) continue;
					i++;
					
					if (i+1 >= len) continue;
					unichar e = src[i+1];
					if (!isUnicharDigit(e) && e != ',') continue;
					i++;
					BOOL comma = (e == ',');
					
					if (!comma) {
						if (i+1 >= len) continue;
						unichar f = src[i+1];
						if (f != ',') continue;
						i++;
					}
					
					if (i+1 >= len) continue;
					unichar g = src[i+1];
					if (!isUnicharDigit(g)) continue;
					i++;
					
					if (i+1 >= len) continue;
					unichar h = src[i+1];
					if (!isUnicharDigit(h)) continue;
					i++;
					break;
				default:
					buf[pos++] = c;
					break;
			}
		}
		else {
			buf[pos++] = c;
		}
	}
	
	return [[[NSString alloc] initWithCharacters:buf length:pos] autorelease];
}

- (BOOL)isChannelName
{
	if (self.length == 0) return NO;
	UniChar c = [self characterAtIndex:0];
	return c == '#' || c == '&' || c == '+' || c == '!';
}

- (BOOL)isModeChannelName
{
	if (self.length == 0) return NO;
	UniChar c = [self characterAtIndex:0];
	return c == '#' || c == '&' || c == '!';
}

- (NSString*)canonicalName
{
	return [self lowercaseString];
}

- (NSRange)rangeOfUrl
{
	return [self rangeOfUrlStart:0];
}

- (NSRange)rangeOfUrlStart:(int)start
{
	if (self.length <= start) return NSMakeRange(NSNotFound, 0);
	
	static OnigRegexp* regex = nil;
	if (!regex) {
		NSString* pattern = @"(?<![a-z0-9_])(https?|ftp|itms)://([^\\s!\"#$\\&'()*+,/;<=>?\\[\\\\\\]\\^_`{|}　、，。．・…]+)(/[^\\s\"'`<>　、，。．・…]*)?";
		regex = [[OnigRegexp compileIgnorecase:pattern] retain];
	}
	
	OnigResult* result = [regex search:self start:start];
	if (!result) return NSMakeRange(NSNotFound, 0);
	
	NSRange r = result.bodyRange;
	
	// exclude non ASCII characters from URLs except for wikipedia
	NSString* host = [[self substringWithRange:[result rangeAt:2]] lowercaseString];
	if (![host hasSuffix:@"wikipedia.org"]) {
		NSRange pathRange = [result rangeAt:3];
		NSString* path = [self substringWithRange:pathRange];
		if (path.length) {
			static OnigRegexp* pathRegex = nil;
			if (!pathRegex) {
				NSString* pathPattern = @"^/[a-zA-Z0-9\\-._~!#$%&'()*+,-./:;=?@\\[\\]]*";
				pathRegex = [[OnigRegexp compile:pathPattern] retain];
			}
			
			OnigResult* pathResult = [pathRegex search:path];
			if (pathResult) {
				NSRange newPathRange = pathResult.bodyRange;
				int delta = pathRange.length - newPathRange.length;
				if (delta > 0) {
					r.length -= delta;
				}
			}
		}
	}
	
	NSString* url = [self substringWithRange:r];
	
	int len = url.length;
	UniChar buf[len];
	CFStringGetCharacters((CFStringRef)url, CFRangeMake(0, len), buf);
	
	int paren = 0;
	
	for (int i=0; i<len; ++i) {
		UniChar c = buf[i];
		if (c == ')') {
			--paren;
		}
		else if (c == '(') {
			++paren;
		}
	}
	
	if (paren < 0) {
		// too much ')'
		for (int i=len-1; i>=0; --i) {
			UniChar c = buf[i];
			if (c == ')') {
				++paren;
				if (paren == 0) {
					len = i;
					r.length = len;
					break;
				}
			}
			else if (c == '(') {
				--paren;
			}
		}
	}
	
	for (int i=len-1; i>=0; --i) {
		UniChar c = buf[i];
		if (c == '.' || c == ',' || c == '?') {
			;
		}
		else {
			len = i + 1;
			r.length = len;
			break;
		}
	}
	
	return r;
}

- (NSRange)rangeOfAddress
{
	return [self rangeOfAddressStart:0];
}

- (NSRange)rangeOfAddressStart:(int)start
{
	int len = self.length;
	if (len <= start) return NSMakeRange(NSNotFound, 0);
	
	static OnigRegexp* regex = nil;
	if (!regex) {
		NSString* pattern = @"([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}|([a-f0-9]{0,4}:){7}[a-f0-9]{0,4}|([0-9]{1,3}\\.){3}[0-9]{1,3}";
		regex = [[OnigRegexp compile:pattern] retain];
	}
	
	OnigResult* result = [regex search:self start:start];
	if (!result) return NSMakeRange(NSNotFound, 0);
	
	NSRange r = result.bodyRange;
	
	int prev = r.location - 1;
	if (0 <= prev && prev < len) {
		// check previous character
		UniChar c = [self characterAtIndex:prev];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	int next = NSMaxRange(r);
	if (next < len) {
		// check next character
		UniChar c = [self characterAtIndex:next];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	return r;
}

- (NSRange)rangeOfChannelName
{
	return [self rangeOfChannelNameStart:0];
}

- (NSRange)rangeOfChannelNameStart:(int)start
{
	int len = self.length;
	if (len <= start) return NSMakeRange(NSNotFound, 0);
	
	static OnigRegexp* regex = nil;
	if (!regex) {
		NSString* pattern = @"(?<![a-zA-Z0-9_])[#\\&][^ \\t,　]+";
		regex = [[OnigRegexp compile:pattern] retain];
	}
	
	OnigResult* result = [regex search:self start:start];
	if (!result) return NSMakeRange(NSNotFound, 0);

	NSRange r = result.bodyRange;
	
	int prev = r.location - 1;
	if (0 <= prev && prev < len) {
		// check previous character
		UniChar c = [self characterAtIndex:prev];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	int next = NSMaxRange(r);
	if (next < len) {
		// check next character
		UniChar c = [self characterAtIndex:next];
		if (IsWordLetter(c)) {
			return [self rangeOfAddressStart:NSMaxRange(r)];
		}
	}
	
	return r;
}

- (NSString*)encodeURIComponent
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString*)encodeURIFragment
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c)
			|| c == '#'
			|| c == '%'
			|| c == '&'
			|| c == '+'
			|| c == ','
			|| c == '-'
			|| c == '.'
			|| c == '/'
			|| c == ':'
			|| c == ';'
			|| c == '='
			|| c == '?'
			|| c == '@'
			|| c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding] autorelease];
}

+ (NSString*)bundleString:(NSString*)key
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}

@end

@implementation NSMutableString (NSMutableStringHelper)

- (NSString*)getToken
{
	static NSCharacterSet* spaceSet = nil;
	if (!spaceSet) {
		spaceSet = [[NSCharacterSet characterSetWithCharactersInString:@" "] retain];
	}
	
	NSRange r = [self rangeOfCharacterFromSet:spaceSet];
	if (r.location != NSNotFound) {
		NSString* result = [self substringToIndex:r.location];
		int len = [self length];
		int pos = r.location + 1;
		while (pos < len && [self characterAtIndex:pos] == ' ') {
			pos++;
		}
		[self deleteCharactersInRange:NSMakeRange(0, pos)];
		return result;
	}
	
	NSString* result = [[self copy] autorelease];
	[self setString:@""];
	return result;
}

- (NSString*)getIgnoreToken
{
	BOOL useAnchor = NO;
	UniChar anchor;
	BOOL escaped = NO;
	
	int len = [self length];
	for (int i=0; i<len; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (i == 0) {
			if (c == '/') {
				useAnchor = YES;
				anchor = '/';
				continue;
			}
			else if (c == '"') {
				useAnchor = YES;
				anchor = '"';
				continue;
			}
		}
		
		if (escaped) {
			escaped = NO;
		}
		else if (c == '\\') {
			escaped = YES;
		}
		else if (useAnchor && c == anchor || !useAnchor && c == ' ') {
			if (useAnchor) {
				++i;
			}
			NSString* result = [self substringToIndex:i];
			
			int right;
			for (right=i+1; right<len; ++right) {
				UniChar c = [self characterAtIndex:right];
				if (c != ' ') {
					break;
				}
			}
			
			if (len <= right) {
				right = len;
			}
			
			[self deleteCharactersInRange:NSMakeRange(0, right)];
			return result;
		}
	}
	
	NSString* result = [[self copy] autorelease];
	[self setString:@""];
	return result;
}

@end
