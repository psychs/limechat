// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogController.h"
#import "LogRenderer.h"
#import "GTMNSString+HTML.h"


#define BOTTOM_EPSILON	20



@interface NSScrollView (Private)
- (void)setAllowsHorizontalScrolling:(BOOL)value;
@end


@interface LogController (Private)
- (void)savePosition;
- (void)restorePosition;
- (void)removeFirstLine:(int)n;
- (NSArray*)buildBody:(LogLine*)line useKeyword:(BOOL)useKeyword;
- (void)writeLine:(NSString*)str attributes:(NSDictionary*)attrs;
- (NSString*)initialDocument;
- (NSString*)defaultCSS;
@end


@implementation LogController

@synthesize view;
@synthesize world;
@synthesize client;
@synthesize channel;
@synthesize menu;
@synthesize urlMenu;
@synthesize addrMenu;
@synthesize chanMenu;
@synthesize memberMenu;
@synthesize keyword;
@synthesize theme;
@synthesize overrideFont;
@synthesize maxLines;
@synthesize console;
@synthesize initialBackgroundColor;

- (id)init
{
	if (self = [super init]) {
		bottom = YES;
		maxLines = 300;
		lines = [NSMutableArray new];
		highlightedLineNumbers = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[view release];
	[policy release];
	[sink release];
	[scroller release];
	[js release];

	[menu release];
	[urlMenu release];
	[addrMenu release];
	[chanMenu release];
	[memberMenu release];
	[keyword release];
	[theme release];
	[overrideFont release];
	[initialBackgroundColor release];
	
	[lines release];
	[highlightedLineNumbers release];
	
	[prevNickInfo release];
	[html release];
	[super dealloc];
}

- (void)setMaxLines:(int)value
{
	if (maxLines == value) return;
	maxLines = value;
	if (!loaded) return;
	
	if (maxLines > 0 && count > maxLines) {
		[self savePosition];
		[self removeFirstLine:count - maxLines];
		[self restorePosition];
	}
}

- (void)setUp
{
	loaded = NO;
	
	policy = [LogPolicy new];
	policy.menuController = [world menuController];
	policy.menu = menu;
	policy.urlMenu = urlMenu;
	policy.addrMenu = addrMenu;
	policy.chanMenu = chanMenu;
	policy.memberMenu = memberMenu;
	
	sink = [LogScriptEventSink new];
	sink.owner = self;
	sink.policy = policy;
	
	if (view) {
		[view removeFromSuperview];
		[view release];
	}
	
	view = [[LogView alloc] initWithFrame:NSZeroRect];
	if ([view respondsToSelector:@selector(setBackgroundColor:)]) [(id)view setBackgroundColor:initialBackgroundColor];
	view.frameLoadDelegate = self;
	view.UIDelegate = policy;
	view.policyDelegate = policy;
	view.resourceLoadDelegate = self;
	view.keyDelegate = self;
	view.resizeDelegate = self;
	view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	//[[view mainFrame] loadHTMLString:[self initialDocument] baseURL:[[theme log] baseurl]];
	[[view mainFrame] loadHTMLString:[self initialDocument] baseURL:nil];
}

- (void)moveToTop
{
	if (!loaded) return;
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	[body setValue:[NSNumber numberWithInt:0] forKey:@"scrollTop"];
}

- (void)moveToBottom
{
	if (!loaded) return;
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
}

- (BOOL)viewingBottom
{
	if (!loaded) return YES;
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return YES;
	DOMHTMLElement* body = [doc body];
	int viewHeight = view.frame.size.height;
	int scrollHeight = [[body valueForKey:@"scrollHeight"] intValue];
	int scrollTop = [[body valueForKey:@"scrollTop"] intValue];
	
	if (viewHeight == 0) return YES;
	return scrollTop + viewHeight >= scrollHeight - BOTTOM_EPSILON;
}

- (void)savePosition
{
	bottom = [self viewingBottom];
}

- (void)restorePosition
{
	if (bottom) {
		[self moveToBottom];
	}
}

- (NSString*)contentString
{
	if (!loaded) return @"";
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return @"";
	return [(DOMHTMLElement*)[[doc body] parentNode] outerHTML];
}

- (void)mark
{
	if (!loaded) return;
	
	[self savePosition];
	[self unmark];
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	DOMHTMLElement* e = (DOMHTMLElement*)[doc createElement:@"hr"];
	[e setAttribute:@"id" value:@"mark"];
	[body appendChild:e];
	
	[self restorePosition];
}

- (void)unmark
{
	if (!loaded) return;
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* e = (DOMHTMLElement*)[doc getElementById:@"mark"];
	if (e) {
		[[doc body] removeChild:e];
	}
}

- (void)goToMark
{
	if (!loaded) return;
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* e = (DOMHTMLElement*)[doc getElementById:@"mark"];
	if (e) {
		int y = 0;
		DOMHTMLElement* t = e;
		while (t) {
			if ([t isKindOfClass:[DOMHTMLElement class]]) {
				y += [[t valueForKey:@"offsetTop"] intValue];
			}
			t = (DOMHTMLElement*)[t parentNode];
		}
		[[doc body] setValue:[NSNumber numberWithInt:y - 20] forKey:@"scrollTop"];
	}
}

- (void)reloadTheme
{
	if (!loaded) return;
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	if (!body) return;
	
	[html release];
	html = [[body innerHTML] retain];
	scrollBottom = [self viewingBottom];
	scrollTop = [[body valueForKey:@"scrollTop"] intValue];
	
	[[view mainFrame] loadHTMLString:[self initialDocument] baseURL:nil];
	[scroller setNeedsDisplay];
}

- (void)clear
{
	if (!loaded) return;
	
	[html release];
	html = nil;
	loaded = NO;
	
	[[view mainFrame] loadHTMLString:[self initialDocument] baseURL:nil];
	[scroller setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
	[self savePosition];
	
	if (bigger) {
		[view makeTextLarger:nil];
	}
	else {
		[view makeTextSmaller:nil];
	}
	
	[self restorePosition];
}

- (void)removeFirstLine:(int)n
{
}

- (BOOL)print:(LogLine*)line useKeyword:(BOOL)useKeyword
{
	NSArray* result = [self buildBody:line useKeyword:useKeyword];
	NSString* body = [result objectAtIndex:0];
	BOOL key = [[result objectAtIndex:1] intValue];
	
	if (!loaded) {
		NSArray* ary = [NSArray arrayWithObjects:line, [NSNumber numberWithBool:useKeyword], nil];
		[lines addObject:ary];
		return key;
	}
	
	NSMutableString* s = [NSMutableString string];
	if (line.time) [s appendFormat:@"<span class=\"time\">%@</span>", [line.time gtm_stringByEscapingForHTML]];
	if (line.place) [s appendFormat:@"<span class=\"place\">%@</span>", [line.place gtm_stringByEscapingForHTML]];
	if (line.nick) {
		[s appendFormat:@"<span class=\"sender\" type=\"%@\"", line.memberType];
		if (!console) [s appendString:@" oncontextmenu=\"on_nick_contextmenu()\""];
		[s appendFormat:@" identified=\"%@\"", line.identified ? @"true" : @"false"];
		if ([line.memberType isEqualToString:@"normal"]) [s appendFormat:@" colornumber=\"%d\"", line.nickColorNumber];
		if (line.nickInfo) [s appendFormat:@" first=\"%@\"", [line.nickInfo isEqualToString:prevNickInfo] ? @"false" : @"true"];
		[s appendFormat:@">%@</span>", [line.nick gtm_stringByEscapingForHTML]];
	}
	
	//
	// @@@ should expand images
	//
	[s appendFormat:@"<span class=\"message\" type=\"%@\">%@</span>", line.lineType, body];
	
	[prevNickInfo autorelease];
	prevNickInfo = [line.nickInfo retain];
	
	NSString* klass;
	NSString* type = line.lineType;
	if ([type isEqualToString:@"privmsg"] || [type isEqualToString:@"notice"] || [type isEqualToString:@"action"]) {
		klass = @"line text";
	}
	else {
		klass = @"line event";
	}
	
	NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
	[attrs setObject:(lineNumber % 2 == 0 ? @"even" : @"odd") forKey:@"alternate"];
	[attrs setObject:klass forKey:@"class"];
	[attrs setObject:type forKey:@"type"];
	[attrs setObject:(key ? @"true" : @"false") forKey:@"highlight"];
	
	if (console && line.clickInfo) {
		[attrs setObject:line.clickInfo forKey:@"clickinfo"];
		[attrs setObject:@"on_dblclick()" forKey:@"ondblclick"];
	}
	
	[self writeLine:s attributes:attrs];

	return key;
}

- (NSArray*)buildBody:(LogLine*)line useKeyword:(BOOL)useKeyword
{
	if (useKeyword) {
		NSString* type = line.lineType;
		if ([type isEqualToString:@"privmsg"] || [type isEqualToString:@"action"]) {
			if ([line.memberType isEqualToString:@"myself"]) {
				useKeyword = NO;
			}
		}
		else {
			useKeyword = NO;
		}
	}
	
	NSArray* keywords = nil;
	NSArray* excludeWords = nil;
	
	if (useKeyword) {
		excludeWords = [keyword dislike_words];
		keywords = [keyword words];
		
		//BOOL currentNick = [keyword current_nick];
		// @@@ add my nick
	}
	
	return [LogRenderer renderBody:line.body
						  keywords:keywords
					  excludeWords:excludeWords
				highlightWholeLine:NO
					exactWordMatch:YES];
}

- (void)writeLine:(NSString*)html attributes:(NSDictionary*)attrs
{
	[self savePosition];
	
	++lineNumber;
	++count;
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	DOMHTMLElement* div = (DOMHTMLElement*)[doc createElement:@"div"];
	[div setInnerHTML:html];
	
	for (NSString* key in attrs) {
		NSString* value = [attrs objectForKey:key];
		[div setAttribute:key value:value];
	}
	[div setAttribute:@"id" value:[NSString stringWithFormat:@"line%d", lineNumber]];
	[body appendChild:div];
	
	if (maxLines > 0 && count > maxLines) {
		[self removeFirstLine:1];
	}
	
	if ([[attrs objectForKey:@"highlight"] isEqualToString:@"true"]) {
		[highlightedLineNumbers addObject:[NSNumber numberWithInt:lineNumber]];
	}
	
	if (scroller) {
		[scroller setNeedsDisplay];
	}
	
	[self restorePosition];
}

- (NSString*)initialDocument
{
	NSString* bodyClass = console ? @"console" : @"normal";
	NSMutableString* bodyAttrs = [NSMutableString string];
	if (channel) {
		[bodyAttrs appendFormat:@"type=\"%@\"", [channel typeStr]];
		if ([channel isChannel]) {
			[bodyAttrs appendFormat:@"channelname=\"%@\"", [[channel name] gtm_stringByEscapingForHTML]];
		}
	}
	else if (console) {
		[bodyAttrs appendString:@"type=\"console\""];
	}
	else {
		[bodyAttrs appendString:@"type=\"server\""];
	}
	
	//NSString* style = [[theme log] content];
	NSString* style = nil;
	
	NSMutableString* s = [NSMutableString string];
	
	[s appendString:@"<html>"];
	[s appendFormat:@"<head class=\"%@\" %@>", bodyClass, bodyAttrs];
	[s appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[s appendString:@"<meta http-equiv=\"Content-Script-Type\" content=\"text/javascript\">"];
	[s appendString:@"<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">"];
	[s appendFormat:@"<style>%@</style>", [self defaultCSS]];
	if (style) [s appendFormat:@"<style><!-- %@ --></style>", style];
	[s appendString:@"</head>"];
	[s appendFormat:@"<body class=\"%@\" %@></body>", bodyClass, bodyAttrs];
	[s appendString:@"</html>"];
	
	return s;
}

- (NSString*)defaultCSS
{
	NSString* fontFamily = @"Courier";
	int fontSize = 9;
	
	NSArray* langs = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
	if (langs && langs.count && [[langs objectAtIndex:0] isEqualToString:@"ja"]) {
		fontFamily = @"Osaka-Mono";
		fontSize = 10;
	}
	
	NSMutableString* s = [NSMutableString string];
	
	[s appendString:@"html {"];
	[s appendFormat:@"font-family:'%@';", fontFamily];
	[s appendFormat:@"font-size:%dpt;", fontSize];
	[s appendString:@"background-color:white;"];
	[s appendString:@"color:black;"];
	[s appendString:@"word-wrap:break-word;"];
	[s appendString:@"margin:0;"];
	[s appendString:@"padding:3px 4px 10px 4px;"];
	[s appendString:@"}"];
	
	[s appendString:@"body {margin:0;padding:0}"];
	[s appendString:@"img {border:1px solid #aaa;vertical-align:top;}"];
	[s appendString:@"object {vertical-align:top;}"];
	[s appendString:@"hr {margin: 0.5em 2em;}"];
	[s appendString:@".line { margin: 0 -4px; padding: 0 4px 1px 4px; }"];
	[s appendString:@".line[alternate=even] {}"];
	[s appendString:@".line[alternate=odd] {}"];
	
	[s appendString:@".line[type=action] .sender:before {"];
	[s appendString:@"content: '• ';"];
	[s appendString:@"white-space: nowrap;"];
	[s appendString:@"}"];
	
	[s appendString:@".inlineimage {"];
	[s appendString:@"margin-top: 10px;"];
	[s appendString:@"margin-bottom: 15px;"];
	[s appendString:@"margin-left: 40px;"];
	[s appendString:@"max-width: 200px;"];
	[s appendString:@"max-height: 150px;"];
	[s appendString:@"-webkit-box-shadow: 2px 2px 2px #888;"];
	[s appendString:@"}"];
	
	[s appendString:@".url { word-break: break-all; }"];
	[s appendString:@".address { text-decoration: underline; word-break: break-all; }"];
	[s appendString:@".highlight { color: #f0f; font-weight: bold; }"];
	[s appendString:@".time { color: #048; }"];
	[s appendString:@".place { color: #008; }"];
	
	[s appendString:@".sender[type=myself] { color: #66a; }"];
	[s appendString:@".sender[type=normal] { color: #008; }"];
	
	[s appendString:@".message[type=system] { color: #080; }"];
	[s appendString:@".message[type=error] { color: #f00; font-weight: bold; }"];
	[s appendString:@".message[type=reply] { color: #088; }"];
	[s appendString:@".message[type=error_reply] { color: #f00; }"];
	[s appendString:@".message[type=dcc_send_send] { color: #088; }"];
	[s appendString:@".message[type=dcc_send_receive] { color: #00c; }"];
	[s appendString:@".message[type=privmsg] {}"];
	[s appendString:@".message[type=notice] { color: #888; }"];
	[s appendString:@".message[type=action] {}"];
	[s appendString:@".message[type=join] { color: #080; }"];
	[s appendString:@".message[type=part] { color: #080; }"];
	[s appendString:@".message[type=kick] { color: #080; }"];
	[s appendString:@".message[type=quit] { color: #080; }"];
	[s appendString:@".message[type=kill] { color: #080; }"];
	[s appendString:@".message[type=nick] { color: #080; }"];
	[s appendString:@".message[type=mode] { color: #080; }"];
	[s appendString:@".message[type=topic] { color: #080; }"];
	[s appendString:@".message[type=invite] { color: #080; }"];
	[s appendString:@".message[type=wallops] { color: #080; }"];
	[s appendString:@".message[type=debug_send] { color: #aaa; }"];
	[s appendString:@".message[type=debug_receive] { color: #444; }"];
	
	[s appendString:@".effect[color-number='0'] { color: #fff; }"];
	[s appendString:@".effect[color-number='1'] { color: #000; }"];
	[s appendString:@".effect[color-number='2'] { color: #008; }"];
	[s appendString:@".effect[color-number='3'] { color: #080; }"];
	[s appendString:@".effect[color-number='4'] { color: #f00; }"];
	[s appendString:@".effect[color-number='5'] { color: #800; }"];
	[s appendString:@".effect[color-number='6'] { color: #808; }"];
	[s appendString:@".effect[color-number='7'] { color: #f80; }"];
	[s appendString:@".effect[color-number='8'] { color: #ff0; }"];
	[s appendString:@".effect[color-number='9'] { color: #0f0; }"];
	[s appendString:@".effect[color-number='10'] { color: #088; }"];
	[s appendString:@".effect[color-number='11'] { color: #0ff; }"];
	[s appendString:@".effect[color-number='12'] { color: #00f; }"];
	[s appendString:@".effect[color-number='13'] { color: #f0f; }"];
	[s appendString:@".effect[color-number='14'] { color: #888; }"];
	[s appendString:@".effect[color-number='15'] { color: #ccc; }"];
	[s appendString:@".effect[bgcolor-number='0'] { background-color: #fff; }"];
	[s appendString:@".effect[bgcolor-number='1'] { background-color: #000; }"];
	[s appendString:@".effect[bgcolor-number='2'] { background-color: #008; }"];
	[s appendString:@".effect[bgcolor-number='3'] { background-color: #080; }"];
	[s appendString:@".effect[bgcolor-number='4'] { background-color: #f00; }"];
	[s appendString:@".effect[bgcolor-number='5'] { background-color: #800; }"];
	[s appendString:@".effect[bgcolor-number='6'] { background-color: #808; }"];
	[s appendString:@".effect[bgcolor-number='7'] { background-color: #f80; }"];
	[s appendString:@".effect[bgcolor-number='8'] { background-color: #ff0; }"];
	[s appendString:@".effect[bgcolor-number='9'] { background-color: #0f0; }"];
	[s appendString:@".effect[bgcolor-number='10'] { background-color: #088; }"];
	[s appendString:@".effect[bgcolor-number='11'] { background-color: #0ff; }"];
	[s appendString:@".effect[bgcolor-number='12'] { background-color: #00f; }"];
	[s appendString:@".effect[bgcolor-number='13'] { background-color: #f0f; }"];
	[s appendString:@".effect[bgcolor-number='14'] { background-color: #888; }"];
	[s appendString:@".effect[bgcolor-number='15'] { background-color: #ccc; }"];	
	
	return s;
}

- (void)setUpScroller
{
	WebFrameView* frame = [[view mainFrame] frameView];
	if (!frame) return;
	
	NSScrollView* scrollView = nil;
	for (NSView* v in [frame subviews]) {
		if ([v isKindOfClass:[NSScrollView class]]) {
			scrollView = (NSScrollView*)v;
			break;
		}
	}
	
	if (!scrollView) return;
	
	[scrollView setHasHorizontalScroller:NO];
	if ([scrollView respondsToSelector:@selector(setAllowsHorizontalScrolling:)]) {
		[(id)scrollView setAllowsHorizontalScrolling:NO];
	}
	
	NSScroller* old = [scrollView verticalScroller];
	if (old && ![old isKindOfClass:[MarkedScroller class]]) {
		if (scroller) {
			[scroller removeFromSuperview];
			[scroller release];
		}
		
		scroller = [[MarkedScroller alloc] initWithFrame:NSMakeRect(-16, -64, 16, 64)];
		scroller.dataSource = self;
		[scroller setFloatValue:[old floatValue] knobProportion:[old knobProportion]];
		[scrollView setVerticalScroller:scroller];
	}
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[js release];
	js = [windowObject retain];
	[js setValue:sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	loaded = YES;
	loadingImages = 0;
	[self setUpScroller];
	
	if (html) {
		DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
		if (doc) {
			DOMHTMLElement* body = [doc body];
			[body setInnerHTML:html];
			[html release];
			html = nil;
			
			if (scrollBottom) {
				[self moveToBottom];
			}
			else if (scrollTop) {
				[body setValue:[NSNumber numberWithInt:scrollTop] forKey:@"scrollTop"];
			}
		}
	}
	else {
		[self moveToBottom];
		bottom = YES;
	}
	
	for (NSArray* ary in lines) {
		LogLine* line = [ary objectAtIndex:0];
		BOOL useKeyword = [[ary objectAtIndex:1] boolValue];
		[self print:line useKeyword:useKeyword];
	}
	[lines removeAllObjects];
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement* body = [doc body];
	DOMHTMLElement* e = (DOMHTMLElement*)[body firstChild];
	while (e) {
		DOMHTMLElement* next = (DOMHTMLElement*)[e nextSibling];
		if (![e isKindOfClass:[DOMHTMLDivElement class]] && ![e isKindOfClass:[DOMHTMLHRElement class]]) {
			[body removeChild:e];
		}
		e = next;
	}
	
	NSMutableString* s = [NSMutableString string];
	
	if (console) {
		[s appendString:@"function on_dblclick() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  while (t && !(t.tagName == 'DIV' && t.className.match(/^line /))) {"];
		[s appendString:@"    t = t.parentNode;"];
		[s appendString:@"  }"];
		[s appendString:@"  if (t) {"];
		[s appendString:@"    app.onDblClick(t.getAttribute('clickinfo'));"];
		[s appendString:@"  }"];
		[s appendString:@"  event.stopPropagation();"];
		[s appendString:@"}"];
		[s appendString:@"function on_mousedown() {"];
		[s appendString:@"  if (app.shouldStopDoubleClick(event)) {"];
		[s appendString:@"    event.preventDefault();"];
		[s appendString:@"  }"];
		[s appendString:@"  event.stopPropagation();"];
		[s appendString:@"}"];
		[s appendString:@"function on_url_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setUrl(t.innerHTML);"];
		[s appendString:@"}"];
		[s appendString:@"function on_address_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setAddr(t.innerHTML);"];
		[s appendString:@"}"];
		[s appendString:@"document.addEventListener('mousedown', on_mousedown, false);"];	}
	else {
		[s appendString:@"function on_url_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setUrl(t.innerHTML);"];
		[s appendString:@"}"];
		[s appendString:@"function on_address_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setAddr(t.innerHTML);"];
		[s appendString:@"}"];
		[s appendString:@"function on_nick_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setNick(t.parentNode.getAttribute('nick'));"];
		[s appendString:@"}"];
		[s appendString:@"function on_channel_contextmenu() {"];
		[s appendString:@"  var t = event.target;"];
		[s appendString:@"  app.setChan(t.innerHTML);"];
		[s appendString:@"}"];
	}
	
	[js evaluateWebScript:s];
	
	// @@@
	// evaluate theme js
}

- (void)logViewKeyDown:(NSEvent *)e
{
	LOG_METHOD
	//[world logKeyDown:e];
}

- (void)logViewOnDoubleClick:(NSString*)e
{
	LOG_METHOD
	//[world log_doubleClick:e];
}

- (void)logViewWillResize
{
	[self savePosition];
}

- (void)logViewDidResize
{
	[self restorePosition];
}

- (NSArray*)markedScrollerPositions:(MarkedScroller*)sender
{
	NSMutableArray* result = [NSMutableArray array];
	
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[[view mainFrame] DOMDocument];
	if (doc) {
		for (NSNumber* n in highlightedLineNumbers) {
			NSString* key = [NSString stringWithFormat:@"line%d", [n intValue]];
			DOMHTMLElement* e = (DOMHTMLElement*)[doc getElementById:key];
			if (e) {
				int pos = [[e valueForKey:@"offsetTop"] intValue] + [[e valueForKey:@"offsetHeight"] intValue] / 2;
				[result addObject:[NSNumber numberWithInt:pos]];
			}
		}
	}
	
	return result;
}

- (NSColor*)markedScrollerColor:(MarkedScroller*)sender
{
	//return [NSColor redColor];
	
	return [[theme other] log_scroller_highlight_color];
}

@end
