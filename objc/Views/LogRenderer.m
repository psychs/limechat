#import "LogRenderer.h"
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


typedef uint16_t flag_t;


void setFlag(flag_t* attr, flag_t flag, int start, int len)
{
	flag_t* target = attr + start;
	flag_t* end = target + len;
	
	while (target < end) {
		*target |= flag;
		++target;
	}
}

int getNextAttributeRange(flag_t* attr, int start, int len)
{
	flag_t target = attr[start];
	
	for (int i=start; i<len; ++i) {
		flag_t t = attr[i];
		if (t != target) {
			return i - start;
		}
	}
	
	return len - start;
}

NSString* renderRange(NSString* body, flag_t attr, int start, int len)
{
	NSString* content = [body substringWithRange:NSMakeRange(start, len)];
	
	if (attr & URL_ATTR) {
		// URL
		NSString* link = content;
		content = [content gtm_stringByEscapingForHTML];
		return [NSString stringWithFormat:@"<a href=\"%@\" class=\"url\" oncontextmenu=\"on_url_contextmenu()\">%@</a>", link, content];
	}
	else {
		return [content gtm_stringByEscapingForHTML];
	}
}



@implementation LogRenderer

+ (NSArray*)renderBody:(NSString*)body
			  keywords:(NSArray*)keywords
		  excludeWords:(NSArray*)excludeWords
	highlightWholeLine:(BOOL)highlightWholeLine
		exactWordMatch:(BOOL)exactWordMatch
{
	int len = body.length;
	int start = 0;
	flag_t attr[len];
	memset(attr, 0, len*sizeof(flag_t));
	
	//
	// URLs
	//
	while (start < len) {
		NSRange r = [body rangeOfUrlStart:start];
		if (r.location == NSNotFound) {
			break;
		}
		
		setFlag(attr, URL_ATTR, r.location, r.length);
		start = NSMaxRange(r) + 1;
	}
	
	//
	// render
	//
	NSMutableString* result = [NSMutableString string];
	
	start = 0;
	while (start < len) {
		int n = getNextAttributeRange(attr, start, len);
		if (n <= 0) break;
		
		flag_t t = attr[start];
		NSString* s = renderRange(body, t, start, n);
		[result appendString:s];
		
		start += n;
	}
	
	return [NSArray arrayWithObjects:result, [NSNumber numberWithBool:0], nil];
}

@end
