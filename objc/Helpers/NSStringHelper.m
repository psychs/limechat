#import "NSStringHelper.h"
#import "UnicodeHelper.h"
#import "Regex.h"


@implementation NSString (NSStringHelper)

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

- (NSString*)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

- (NSRange)rangeOfUrl
{
	return [self rangeOfUrlStart:0];
}

- (NSRange)rangeOfUrlStart:(int)start
{
	if (self.length <= start) return NSMakeRange(NSNotFound, 0);
	
	static Regex* schemeRegex = nil;
	if (!schemeRegex) {
		NSString* pattern = @"(https?|ftp|itms)://[^\\s!\"#$&'()*+,/;<=>?\\[\\\\\\]^_`{|}　、，。．・…]+(/[^\\s\"'`<>　、，。．・…]*)?";
		schemeRegex = [[Regex alloc] initWithString:pattern options:UREGEX_CASE_INSENSITIVE];
	}
	
	NSRange r = [schemeRegex match:self start:start];
	[schemeRegex reset];
	if (r.location == NSNotFound) return r;
	
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

+ (NSString*)bundleString:(NSString*)key
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}

@end

@implementation NSMutableString (NSMutableStringHelper)

- (NSString*)getToken
{
	NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
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

@end
