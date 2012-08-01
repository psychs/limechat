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

    DOMElement *meta = [doc querySelector:@"meta[property=\"og:image\"]"];
    NSMutableString *img = nil;
    if (meta)
        img = [[[meta getAttribute:@"content"] mutableCopy] autorelease];

    if (!img) // bail
    {
        NSLog(@"og:image for Pixiv ID %@ could not be extracted", illustId);
        if ([delegate respondsToSelector:@selector(pixivClient:gotError::)])
            [delegate pixivClient:self gotError:[NSError errorWithDomain:@"Pixiv Client" code:-1 userInfo:nil]];
        return;
    }

    /* _s images are too small; we're going to use _m images from the 320x320 folder.
       They're not as small as _s but not as large as regular _m images. */
    [img replaceOccurrencesOfString:@"_s." withString:@"_m." options:0 range:NSMakeRange(0, [img length])];
    [img replaceOccurrencesOfString:@"/img/" withString:@"/dic/320x320/" options:0 range:NSMakeRange(0, [img length])];

    NSURL *url = [NSURL URLWithString:img];
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
