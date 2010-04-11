// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "PasteSheet.h"
#import "NSStringHelper.h"


static NSArray* SYNTAXES;


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
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"PasteSheet" owner:self];
		
		if (!SYNTAXES) {
			SYNTAXES = [[NSArray arrayWithObjects:
						 @"privmsg", @"notice", @"c", @"css", @"diff", @"html",
						 @"java", @"javascript", @"php", @"plain text", @"python",
						 @"ruby", @"sql", @"shell script", @"perl", @"haskell",
						 @"scheme", @"objective-c",
						 nil] retain];
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
	
	[self startSheet];
}

- (void)pasteOnline:(id)sender
{
	LOG_METHOD
	
	[self setRequesting:YES];
}

- (void)sendInChannel:(id)sender
{
	LOG_METHOD
	
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
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(pasteSheetWillClose:)]) {
		[delegate pasteSheetWillClose:self];
	}
}

@end
