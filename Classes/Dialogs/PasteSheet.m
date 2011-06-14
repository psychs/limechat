// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "PasteSheet.h"
#import "NSStringHelper.h"


static NSArray* SYNTAXES;
static NSDictionary* SYNTAX_EXT_MAP;


@interface PasteSheet (Private)
- (void)setRequesting:(BOOL)value;
- (int)tagFromSyntax:(NSString*)s;
- (NSString*)syntaxFromTag:(int)tag;
@end


@implementation PasteSheet

@synthesize nick;
@synthesize uid;
@synthesize cid;
@synthesize originalText;
@synthesize syntax;
@synthesize command;
@synthesize size;
@synthesize editMode;
@synthesize isShortText;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"PasteSheet" owner:self];
		
		if (!SYNTAXES) {
			SYNTAXES = [[NSArray arrayWithObjects:
						 @"privmsg", @"notice", @"c", @"css", @"diff", @"html",
						 @"java", @"javascript", @"php", @"plain text", @"python",
						 @"ruby", @"sql", @"shell script", @"perl", @"haskell",
						 @"scheme", @"objective-c",
						 nil] retain];
		}
		
		if (!SYNTAX_EXT_MAP) {
			SYNTAX_EXT_MAP = [[NSDictionary dictionaryWithObjectsAndKeys:
							   @".h", @"c",
							   @".css", @"css",
							   @".diff", @"diff",
							   @".lhs", @"haskell",
							   @".html", @"html",
							   @".groovy", @"java",
							   @".js", @"javascript",
							   @".mm", @"objective-c",
							   @".ph", @"perl",
							   @".php[345]", @"php",
							   @".txt", @"plain_text",
							   @".pyw", @"python",
							   @".ru", @"ruby",
							   @".sls", @"scheme",
							   @".sh", @"shell script",
							   @".sql", @"sql",
							   nil, nil] retain];
		}
	}
	return self;
}

- (void)dealloc
{
	[nick release];
	[originalText release];
	[syntax release];
	[command release];
	[gist cancel];
	[gist autorelease];
	[super dealloc];
}

- (void)start
{
	if (editMode) {
		NSArray* lines = [originalText splitIntoLines];
		isShortText = lines.count <= 3;
		if (isShortText) {
			self.syntax = @"privmsg";
		}
		[sheet makeFirstResponder:bodyText];
	}
	
	[syntaxPopup selectItemWithTag:[self tagFromSyntax:syntax]];
	[commandPopup selectItemWithTag:[self tagFromSyntax:command]];
	[bodyText setString:originalText];
	
	if (!NSEqualSizes(size, NSZeroSize)) {
		[sheet setContentSize:size];
	}
	
	[self startSheet];
}

- (void)pasteOnline:(id)sender
{
	[self setRequesting:YES];
	
	if (gist) {
		[gist cancel];
		[gist autorelease];
	}
	
	NSString* s = bodyText.string;
	NSString* fileType = [SYNTAX_EXT_MAP objectForKey:[self syntaxFromTag:syntaxPopup.selectedTag]];
	if (!fileType) {
		fileType = @".txt";
	}
	
	gist = [GistClient new];
	gist.delegate = self;
	[gist send:s fileType:fileType private:YES];
}

- (void)sendInChannel:(id)sender
{
	[command release];
	command = [[self syntaxFromTag:commandPopup.selectedTag] retain];
	
	NSString* s = bodyText.string;

	if ([delegate respondsToSelector:@selector(pasteSheet:onPasteText:)]) {
		[delegate pasteSheet:self onPasteText:s];
	}
	
	[self endSheet];
}

- (void)cancel:(id)sender
{
	if ([delegate respondsToSelector:@selector(pasteSheetOnCancel:)]) {
		[delegate pasteSheetOnCancel:self];
	}
	
	[super cancel:nil];
}

- (void)setRequesting:(BOOL)value
{
	errorLabel.stringValue = value ? @"Sending…" : @"";
	if (value) {
		[uploadIndicator startAnimation:nil];
	}
	else {
		[uploadIndicator stopAnimation:nil];
	}
	
	[pasteOnlineButton setEnabled:!value];
	[sendInChannelButton setEnabled:!value];
	[syntaxPopup setEnabled:!value];
	[commandPopup setEnabled:!value];
	
	if (value) {
		[bodyText setEditable:NO];
		[bodyText setTextColor:[NSColor disabledControlTextColor]];
		[bodyText setBackgroundColor:[NSColor windowBackgroundColor]];
	}
	else {
		[bodyText setTextColor:[NSColor textColor]];
		[bodyText setBackgroundColor:[NSColor textBackgroundColor]];
		[bodyText setEditable:YES];
	}
}

- (int)tagFromSyntax:(NSString*)s
{
	NSUInteger n = [SYNTAXES indexOfObject:s];
	if (n != NSNotFound) {
		return n;
	}
	return -1;
}

- (NSString*)syntaxFromTag:(int)tag
{
	if (0 <= tag && tag < SYNTAXES.count) {
		return [SYNTAXES objectAtIndex:tag];
	}
	return nil;
}

#pragma mark -
#pragma mark GistClient Delegate

- (void)gistClient:(GistClient*)sender didReceiveResponse:(NSString*)url
{
	[gist autorelease];
	gist = nil;

	[self setRequesting:NO];
	
	if (url.length) {
		[errorLabel setStringValue:@""];
		
		if ([delegate respondsToSelector:@selector(pasteSheet:onPasteURL:)]) {
			[delegate pasteSheet:self onPasteURL:url];
		}
		
		[self endSheet];
	}
	else {
		[errorLabel setStringValue:@"Could not get an URL from Gist"];
	}
}

- (void)gistClient:(GistClient*)sender didFailWithError:(NSString*)error statusCode:(int)statusCode
{
	[gist autorelease];
	gist = nil;
	
	[self setRequesting:NO];
	[errorLabel setStringValue:[NSString stringWithFormat:@"Gist error: %@", error]];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	[syntax release];
	[command release];
	syntax = [[self syntaxFromTag:syntaxPopup.selectedTag] retain];
	command = [[self syntaxFromTag:commandPopup.selectedTag] retain];
	
	NSView* contentView = [sheet contentView];
	size = contentView.frame.size;
	
	if ([delegate respondsToSelector:@selector(pasteSheetWillClose:)]) {
		[delegate pasteSheetWillClose:self];
	}
}

@end
