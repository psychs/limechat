// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogController.h"
#import "LogRenderer.h"
#import "GTMNSString+HTML.h"


#define BOTTOM_EPSILON	20


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
	}
	return self;
}

- (void)dealloc
{
	[view release];
	[policy release];
	[sink release];
	[scroller release];
	
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
	[view setBackgroundColor:initialBackgroundColor];
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
	[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
}

- (void)moveToBottom
{
}

- (BOOL)viewingBottom
{
	return YES;
}

- (void)savePosition
{
}

- (void)restorePosition
{
}

- (NSString*)contentString
{
	return @"";
}

- (void)mark
{
}

- (void)unmark
{
}

- (void)goToMark
{
}

- (void)reloadTheme
{
}

- (void)clear
{
}

- (void)changeTextSize:(BOOL)bigger
{
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
	NSMutableString* s = [NSMutableString string];
	
	[s appendString:@"<html>"];
	[s appendString:@"<head>"];
	[s appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[s appendString:@"<meta http-equiv=\"Content-Script-Type\" content=\"text/javascript\">"];
	[s appendString:@"<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">"];
	[s appendFormat:@"<style>%@</style>", [self defaultCSS]];
	[s appendString:@"</head>"];
	[s appendString:@"<body></body>"];
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

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	loaded = YES;
	loadingImages = 0;
	
	//@@@
}



















































@end
