// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSStringHelper.h"
#import "UnicodeHelper.h"


#define LF  (0xa)
#define CR  (0xd)


@implementation NSString (NSStringHelper)

- (const UniChar*)getCharactersBuffer
{
    NSUInteger len = self.length;
    const UniChar* buffer = CFStringGetCharactersPtr((CFStringRef)self);
    if (!buffer) {
        NSMutableData* data = [NSMutableData dataWithLength:len * sizeof(UniChar)];
        if (!data) return NULL;
        [self getCharacters:[data mutableBytes] range:NSMakeRange(0, len)];
        buffer = [data bytes];
        if (!buffer) return NULL;
    }
    return buffer;
}

- (BOOL)isEqualNoCase:(NSString*)other
{
    return [self caseInsensitiveCompare:other] == NSOrderedSame;
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
    }
    else {
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
    const UniChar* buf = [self getCharactersBuffer];
    if (!buf) {
        return [NSArray array];
    }

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

            start = i + 1;
        }
    }

    NSString* s = [[NSString alloc] initWithCharacters:buf+start length:len - start];
    [lines addObject:s];

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

static BOOL isUnicharDigit(unichar c)
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

    return [[NSString alloc] initWithCharacters:dest length:n];
}

- (NSString*)safeFileName
{
    NSString* s = [self stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [s stringByReplacingOccurrencesOfString:@":" withString:@"_"];
}

- (NSString*)stripMIRCEffects
{
    int len = self.length;
    if (len == 0) return self;

    const UniChar* src = [self getCharactersBuffer];
    if (!src) return self;

    UniChar buf[len];
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

    return [[NSString alloc] initWithCharacters:buf length:pos];
}

- (BOOL)isChannelName
{
    if (self.length == 0) return NO;
    UniChar c = [self characterAtIndex:0];
    return c == '#' || c == '&' || c == '+' || c == '!' || c == '~';
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
    if (self.length <= start) {
        return NSMakeRange(NSNotFound, 0);
    }

    static NSRegularExpression* regex = nil;
    if (!regex) {
        NSString* pattern = @"(?<![a-z0-9_])(https?|ftp|itms|afp)://([^\\s!\"#$\\&'()*+,/;<=>?\\[\\\\\\]\\^_`{|}　、，。．・…]+)(/[^\\s\"`<>　、，。．・…]*)?";
        regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    }

    NSTextCheckingResult* result = [regex firstMatchInString:self options:0 range:NSMakeRange(start, self.length - start)];
    if (!result || result.numberOfRanges < 4) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSRange r = [result rangeAtIndex:0];

    // exclude non ASCII characters from URLs except for wikipedia
    NSString* host = [[self substringWithRange:[result rangeAtIndex:2]] lowercaseString];
    if (![host hasSuffix:@"wikipedia.org"]) {
        NSRange pathRange = [result rangeAtIndex:3];
        if (pathRange.length) {
            static NSRegularExpression* pathRegex = nil;
            if (!pathRegex) {
                NSString* pathPattern = @"^/[a-zA-Z0-9\\-._~!#$%&'()*+,-./:;=?@\\[\\]]*";
                pathRegex = [[NSRegularExpression alloc] initWithPattern:pathPattern options:0 error:NULL];
            }

            NSString* path = [self substringWithRange:pathRange];
            NSRange newPathRange = [pathRegex rangeOfFirstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
            if (newPathRange.location != NSNotFound) {
                int delta = pathRange.length - newPathRange.length;
                if (delta > 0) {
                    r.length -= delta;
                }
            }
        }
    }

    NSString* url = [self substringWithRange:r];
    int len = url.length;
    const UniChar* buf = [url getCharactersBuffer];
    if (!buf) {
        return NSMakeRange(NSNotFound, 0);
    }

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
    if (len <= start) {
        return NSMakeRange(NSNotFound, 0);
    }

    static NSRegularExpression* regex = nil;
    if (!regex) {
        NSString* pattern = @"([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}|([a-f0-9]{0,4}:){7}[a-f0-9]{0,4}|([0-9]{1,3}\\.){3}[0-9]{1,3}";
        regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:NULL];
    }

    NSRange r = [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(start, self.length - start)];
    if (r.location == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }

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
    if (len <= start) {
        return NSMakeRange(NSNotFound, 0);
    }

    static NSRegularExpression* regex = nil;
    if (!regex) {
        NSString* pattern = @"(?<![a-zA-Z0-9_])[#\\&][^ \\t,　]+";
        regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:NULL];
    }

    NSRange r = [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(start, self.length - start)];
    if (r.location == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }

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

    return [[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding];
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

    return [[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding];
}

#define UnicodeIsSpace(c) ({ __typeof__(c) __c = (c); (__c) == 0x9 || (__c) == 0x20 || (__c) == 0xA0 || (__c) == 0x1680 || (__c) == 0x180E || (0x2000 <= (__c) && (__c) <= 0x200A) || (__c) == 0x202F || (__c) == 0x205F || (__c) == 0x3000; })
#define UnicodeIsCombiningMark(c) ({ __typeof__(c) __c = (c); (0x300 <= (__c) && (__c) <= 0x36F) || (0x483 <= (__c) && (__c) <= 0x487) || (__c) == 0x135F || (0x1DC0 <= (__c) && (__c) <= 0x1DFF) || (0x20D0 <= (__c) && (__c) <= 0x20FF) || (0x2DE0 <= (__c) && (__c) <= 0x2DFF) || (0x302A <= (__c) && (__c) <= 0x302D) || (0x3099 <= (__c) && (__c) <= 0x309A) || (0xA67C <= (__c) && (__c) <= 0xA67D) || (0xFE20 <= (__c) && (__c) <= 0xFE2F); })
#define UnicodeIsZeroWidth(c) ({ __typeof__(c) __c = (c); (0x200B <= (__c) && (__c) <= 0x200F) || (0x202A <= (__c) && (__c) <= 0x202E) || (0x2060 <= (__c) && (__c) <= 0x2064) || (0x206A <= (__c) && (__c) <= 0x206F) || (__c) == 0xFEFF || (0xFFF9 <= (__c) && (__c) <= 0xFFFB); })

#define kUnicodeWhiteSquare ((UniChar)0x25A1)

- (NSString*)lcf_stringByRemovingCrashingSequences
{
    NSInteger len = self.length;
    if (!len) {
        return self;
    }

    UniChar buf[len];
    [self getCharacters:buf range:NSMakeRange(0, len)];

    BOOL changed = NO;

    for (NSInteger i=0; i<len; i++) {
        UniChar c = buf[i];
        if (UnicodeIsSpace(c)) {
            NSInteger count = 0;
            NSInteger pos = i + 1;
            for (; pos<len; pos++) {
                UniChar d = buf[pos];
                if (UnicodeIsCombiningMark(d)) {
                    count++;
                } else if (UnicodeIsZeroWidth(d)) {
                    // Ignore
                } else {
                    break;
                }
            }

            if (count >= 3) {
                // Replace with white squares
                changed = YES;
                for (NSInteger j=i+1; j<pos; j++) {
                    buf[j] = kUnicodeWhiteSquare;
                }
                i = pos - 1;
            }
        }
    }

    NSString *result = self;
    if (changed) {
        result = [[NSString alloc] initWithCharacters:buf length:len];
    }
    return result;
}

+ (NSString*)lcf_uuidString
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return uuidString;
}

@end


@implementation NSMutableString (NSMutableStringHelper)

- (NSString*)getToken
{
    static NSCharacterSet* spaceSet = nil;
    if (!spaceSet) {
        spaceSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
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

    NSString* result = [self copy];
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
        else if ((useAnchor && c == anchor) || (!useAnchor && c == ' ')) {
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

    NSString* result = [self copy];
    [self setString:@""];
    return result;
}

@end
