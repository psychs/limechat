// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "PixivIllustClient.h"
#import "PixivSchemaManager.h"
#import "Preferences.h"

#define PIXIV_ILLUST_FORMAT @"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@"

@implementation PixivIllustClient

@synthesize delegate, client, illustId;

- (id)init
{
    self = [super init];
    if (self) {
        webView = [[WebView alloc] init];
        webView.frameLoadDelegate    = self;
        webView.resourceLoadDelegate = self;
        loggingIn = NO;
    }
    return self;
}

+ (PixivIllustClient *)newWithIllustId:(NSString *)illustId
{
    PixivIllustClient *c = [PixivIllustClient new];
    c.illustId = illustId;
    return c;
}

- (void)dealloc
{
    [self cancel];
    [webView release];
    webView = nil;
    [requestURL release];
    requestURL = nil;
    [super dealloc];
}

- (void)cancel
{
    [[webView mainFrame] stopLoading];
}

- (void)beginQuery
{
    [self cancel];

    requestURL = [NSURL URLWithString:[NSString stringWithFormat:PIXIV_ILLUST_FORMAT, illustId]];
    [requestURL retain];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:requestURL];

    [[webView mainFrame] loadRequest:req];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame != [webView mainFrame])
        return;
    DOMDocument *doc = [frame DOMDocument];

    DOMElement *mustLogin = [doc querySelector:@"div.header_index_login div span.error"];
    DOMElement *notFound = [doc querySelector:@"span.error strong"];
    DOMElement *img = [doc querySelector:@"div.works_display a img"];

    if (mustLogin)
    {
        NSLog(@"Pixiv ID %@ needs pixiv.net login on Safari (R-18? mypic?)", illustId);
        return;
    }
    else if (notFound)
    {
        NSLog(@"Pixiv ID %@ doesn't exist", illustId);
        if ([delegate respondsToSelector:@selector(pixivClient:gotError:)])
            [delegate pixivClient:self gotError:[NSError errorWithDomain:@"Pixiv Client" code:PixivError404 userInfo:nil]];
        return;
    }
    else if (!img) // image might be available as a preview
        img = [doc querySelector:@"div.front-centered a img"];

    if (!img) // bail
    {
        NSLog(@"Pixiv Image URL for ID %@ could not be extracted", illustId);
        if ([delegate respondsToSelector:@selector(pixivClient:gotError:)])
            [delegate pixivClient:self gotError:[NSError errorWithDomain:@"Pixiv Client" code:PixivErrorUnknown userInfo:nil]];
        return;
    }

    NSLog(@"Pixiv ID %@ successfully parsed", illustId);
    NSMutableString *src = [[img getAttribute:@"src"] mutableCopy];
    /* Regular images are too large; _s images are too small.
       Pixiv has a 320x320 folder so we use that. */
    [src replaceOccurrencesOfString:@"/img/" withString:@"/dic/320x320/" options:0 range:NSMakeRange(0, [src length])];
    [src autorelease];
    NSURL *url = [NSURL URLWithString:src];
    if ([delegate respondsToSelector:@selector(pixivClient:gotPixivIllustURL:)])
        [delegate pixivClient:self gotPixivIllustURL:url];
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    /* WebKit wants to load *everything* that's referenced from the page;
       we only need the HTML */
    if (redirectResponse)
        return request;
    if ([[request URL] isEqual:requestURL])
        return request;
    return nil;
}

@end
