#import "NSStringHelper.h"
#import "UnicodeHelper.h"


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

- (NSString*)decodeAsURIComponent
{
	if ([self length] == 0) return self;
	
	const char* p = [self UTF8String];
	char* buf = alloca(strlen(p)+1);
	char* dst = buf;
	
	char* next;
	while (next = strchr(p, '%')) {
		if (p < next) {
			int n = next - p;
			memcpy(dst, p, n);
			p += n;
			dst += n;
		}
		
		++p;
		if (!*p) break;
		unsigned char c = *p++;
		if (!*p) break;
		unsigned char d = *p++;
		*dst++ = (ctoi(c) << 4) | ctoi(d);
	}
	
	int n = strlen(p);
	if (n > 0) {
		memcpy(dst, p, n);
		dst += n;
	}
	*dst = 0;
	
	return [NSString stringWithUTF8String:buf];
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
	
	NSRange r = [self rangeOfString:@"http" options:NSCaseInsensitiveSearch range:NSMakeRange(start, self.length - start)];
	if (r.location == NSNotFound) return r;
	
	int n = NSMaxRange(r);
	if (self.length <= n) return NSMakeRange(NSNotFound, 0);
	
	UniChar c = [self characterAtIndex:n];
	if (c == 's' || c == 'S') {
		n++;
		if (self.length <= n) return NSMakeRange(NSNotFound, 0);
		c = [self characterAtIndex:n];
	}
	
	if (c != ':') return [self rangeOfUrlStart:n];
	n++;
	if (self.length <= n) return NSMakeRange(NSNotFound, 0);
	c = [self characterAtIndex:n];
	
	if (c != '/') return [self rangeOfUrlStart:n];
	n++;
	if (self.length <= n) return NSMakeRange(NSNotFound, 0);
	c = [self characterAtIndex:n];
	
	if (c != '/') return [self rangeOfUrlStart:n];
	n++;
	if (self.length <= n) return NSMakeRange(NSNotFound, 0);
	
	
	int paren = 0;
	int end = -1;
	BOOL foundSlash = NO;
	BOOL allowIdeograph = NO;
	
	for (int i=n,size=self.length; i<size; i++) {
		c = [self characterAtIndex:i];
		if (c <= 0x20 || c == '<' || c == '>') {
			end = i;
			break;
		}
		else if (c == '(') {
			paren++;
		}
		else if (c == ')') {
			paren--;
		}
		else if (c == '/') {
			foundSlash = YES;
		}
		else {
			if (allowIdeograph) {
				if ([UnicodeHelper isPrivate:c]) {
					end = i;
					break;
				}
			}
			else if (foundSlash) {
				if ([UnicodeHelper isIdeographicOrPrivate:c]) {
					end = i;
					break;
				}
			}
			else {
				if ([UnicodeHelper isPrivate:c]) {
					end = i;
					break;
				}
				else if ([UnicodeHelper isIdeographic:c]) {
					allowIdeograph = YES;
				}
			}
		}
	}
	
	if (end < 0) {
		r = NSMakeRange(r.location, self.length-r.location);
	}
	else {
		r = NSMakeRange(r.location, end-r.location);
	}
	
	NSString* url = [self substringWithRange:r];
	
	if ([url hasSuffix:@")."]) {
		r.length -= 2;
		++paren;
		url = [url substringToIndex:url.length - 2];
	}
	else if ([url hasSuffix:@"),"]) {
		r.length -= 2;
		++paren;
		url = [url substringToIndex:url.length - 2];
	}
	else if ([url hasSuffix:@"."]) {
		--r.length;
		url = [url substringToIndex:url.length - 1];
	}
	else if ([url hasSuffix:@","]) {
		--r.length;
		url = [url substringToIndex:url.length - 1];
	}
	
	while ([url hasSuffix:@")"] && paren < 0) {
		--r.length;
		++paren;
		url = [url substringToIndex:url.length - 1];
	}
	
	return r;
}

- (NSString*)isYouTubeURL
{
	NSString* url = self;
	
	if ([url hasPrefix:@"http://"]) {
		if ([url hasPrefix:@"http://youtube.com/"] || [url hasPrefix:@"http://www.youtube.com/"]) {
			return url;
		}
		else {
			NSRange r = [url rangeOfString:@"youtube.com/"];
			if (r.location != NSNotFound) {
				return [NSString stringWithFormat:@"http://youtube.com/%@", [url substringFromIndex:NSMaxRange(r)]];
			}
		}
	}
	return nil;
}

- (NSString*)isGoogleMapsURL
{
	NSString* url = self;
	
	if ([url hasPrefix:@"http://"]) {
		if ([url hasPrefix:@"http://maps.google."]) {
			if (![url hasPrefix:@"http://maps.google.com"]) {
				NSRange r = [url rangeOfString:@"/" options:0 range:NSMakeRange(7, [url length] - 7)];
				if (r.location == NSNotFound) {
					url = @"http://maps.google.com/";
				} else {
					url = [NSString stringWithFormat:@"http://maps.google.com%@", [url substringFromIndex:r.location]];
				}
			}
			return url;
		}
	}
	return nil;
}

- (BOOL)isAppStoreURL
{
	NSString* url = self;
	
	if ([url hasPrefix:@"http://phobos.apple.com"]) {
		return YES;
	}
	
	return NO;
}

+ (NSString*)preferredLanguage
{
	static NSString* lang = nil;
	if (!lang) {
		NSArray* langs = [NSLocale preferredLanguages];
		if (langs && langs.count > 0) {
			lang = [[langs objectAtIndex:0] retain];
		}
		else {
			lang = @"en";
		}
	}
	return lang;
}

+ (NSString*)localeLanguage
{
	static NSString* code = nil;
	if (!code) {
		CFLocaleRef userLocale = CFLocaleCopyCurrent();
		code = (NSString*)CFLocaleGetValue(userLocale, kCFLocaleLanguageCode);
		[code retain];
		CFRelease(userLocale);
	}
	return code;
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
