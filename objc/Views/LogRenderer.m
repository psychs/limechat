#import "LogRenderer.h"
#import "Regex.h"
#import "NSStringHelper.h"
#import "GTMNSString+HTML.h"


#define URL_ATTR				(1 << 15)
#define ADDRESS_ATTR			(1 << 14)
#define CHANNEL_NAME_ATTR		(1 << 13)
#define KEYWORD_ATTR			(1 << 12)
#define BOLD_ATTR				(1 << 11)
#define UNDERLINE_ATTR			(1 << 10)
#define ITALIC_ATTR				(1 <<  9)
#define COLOR_ATTR				(1 <<  8)
#define BACKGROUND_COLOR_MASK	(0xF0)
#define TEXT_COLOR_MASK			(0x0F)

#define EFFECT_ATTR				(BOLD_ATTR | UNDERLINE_ATTR | ITALIC_ATTR | COLOR_ATTR)


typedef uint16_t attr_t;


static void setFlag(attr_t* attrBuf, attr_t flag, int start, int len)
{
	attr_t* target = attrBuf + start;
	attr_t* end = target + len;
	
	while (target < end) {
		*target |= flag;
		++target;
	}
}

static BOOL isClear(attr_t* attrBuf, int start, int len)
{
	attr_t* target = attrBuf + start;
	attr_t* end = target + len;
	
	while (target < end) {
		if (*target) return NO;
		++target;
	}
	
	return YES;
}

static int getNextAttributeRange(attr_t* attrBuf, int start, int len)
{
	attr_t target = attrBuf[start];
	
	for (int i=start; i<len; ++i) {
		attr_t t = attrBuf[i];
		if (t != target) {
			return i - start;
		}
	}
	
	return len - start;
}

static NSString* renderRange(NSString* body, attr_t attr, int start, int len)
{
	NSString* content = [body substringWithRange:NSMakeRange(start, len)];
	
	if (attr & URL_ATTR) {
		// URL
		NSString* link = content;
		content = [content gtm_stringByEscapingForHTML];
		return [NSString stringWithFormat:@"<a href=\"%@\" class=\"url\" oncontextmenu=\"on_url_contextmenu()\">%@</a>", link, content];
	}
	else if (attr & ADDRESS_ATTR) {
		// address
		content = [content gtm_stringByEscapingForHTML];
		return [NSString stringWithFormat:@"<span class=\"address\" oncontextmenu=\"on_address_contextmenu()\">%@</span>", content];
	}
	else if (attr & CHANNEL_NAME_ATTR) {
		// channel name
		content = [content gtm_stringByEscapingForHTML];
		return [NSString stringWithFormat:@"<span class=\"channel\" oncontextmenu=\"on_channel_contextmenu()\">%@</span>", content];
	}
	else {
		return [content gtm_stringByEscapingForHTML];
	}
}


static Regex* addressRegex;


@implementation LogRenderer

+ (void)setUp
{
	addressRegex = [[Regex alloc] initWithString:@""];
}

+ (NSArray*)renderBody:(NSString*)body
			  keywords:(NSArray*)keywords
		  excludeWords:(NSArray*)excludeWords
	highlightWholeLine:(BOOL)highlightWholeLine
		exactWordMatch:(BOOL)exactWordMatch
{
	int len = body.length;
	attr_t attrBuf[len];
	memset(attrBuf, 0, len * sizeof(attr_t));
	
	int start;
	
	//
	// URL
	//
	start = 0;
	while (start < len) {
		NSRange r = [body rangeOfUrlStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		setFlag(attrBuf, URL_ATTR, r.location, r.length);
		start = NSMaxRange(r) + 1;
	}
	
	//
	// address
	//
	start = 0;
	while (start < len) {
		NSRange r = [body rangeOfAddressStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		if (isClear(attrBuf, r.location, r.length)) {
			setFlag(attrBuf, ADDRESS_ATTR, r.location, r.length);
		}
		
		start = NSMaxRange(r) + 1;
	}
	
	//
	// channel name
	//
	start = 0;
	while (start < len) {
		NSRange r = [body rangeOfChannelNameStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		if (isClear(attrBuf, r.location, r.length)) {
			setFlag(attrBuf, CHANNEL_NAME_ATTR, r.location, r.length);
		}
		
		start = NSMaxRange(r) + 1;
	}
	
	//
	// render
	//
	NSMutableString* result = [NSMutableString string];
	
	start = 0;
	while (start < len) {
		int n = getNextAttributeRange(attrBuf, start, len);
		if (n <= 0) break;
		
		attr_t t = attrBuf[start];
		NSString* s = renderRange(body, t, start, n);
		[result appendString:s];
		
		start += n;
	}
	
	return [NSArray arrayWithObjects:result, [NSNumber numberWithBool:0], nil];
}

@end
