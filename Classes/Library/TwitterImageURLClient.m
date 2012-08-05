// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TwitterImageURLClient.h"
#import "GTMNSString+URLArguments.h"


#define TWITTER_IMAGE_URL_CLIENT_TIMEOUT    30


@interface TwitterImageURLClient ()
- (void)getResultCode;
@end


static void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType type, void* userData)
{
    TwitterImageURLClient* client = (TwitterImageURLClient*)userData;

    switch (type) {
        case kCFStreamEventErrorOccurred:
        case kCFStreamEventEndEncountered:
            [client getResultCode];
            break;
        default:
            break;
    }
}

static void* CFClientRetain(void* obj)
{
    return [(id)obj retain];
}

static void CFClientRelease(void* obj)
{
    [(id)obj release];
}

static CFStringRef CFClientDescribeCopy(void* obj)
{
    return (CFStringRef)[[(id)obj description] copy];
}


@implementation TwitterImageURLClient

@synthesize delegate;
@synthesize screenName;

- (id)init
{
    self = [super init];
    if (self) {
        context.version = 0;
        context.info = self;
        context.retain = CFClientRetain;
        context.release = CFClientRelease;
        context.copyDescription = CFClientDescribeCopy;
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
    [screenName release];
    [super dealloc];
}

- (void)cancel
{
    if (stream) {
        CFReadStreamClose(stream);
        CFReadStreamSetClient(stream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(stream);
        stream = NULL;
    }

    if (timeoutTimer) {
        [timeoutTimer invalidate];
        [timeoutTimer release];
        timeoutTimer = nil;
    }
}

- (void)getImageURL
{
    [self cancel];

    NSString* url = [NSString stringWithFormat:@"http://api.twitter.com/1/users/profile_image?size=normal&screen_name=%@", [screenName gtm_stringByEscapingForURLArgument]];
    NSURL* urlObj = [NSURL URLWithString:url];
    if (!urlObj) {
        if ([delegate respondsToSelector:@selector(twitterImageURLClientDidReceiveBadURL:)]) {
            [delegate twitterImageURLClientDidReceiveBadURL:self];
        }
        return;
    }

    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)@"HEAD", (CFURLRef)urlObj, kCFHTTPVersion1_1);
    stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    CFRelease(request);

    CFReadStreamSetClient(stream,
                          kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
                          readStreamEventHandler,
                          &context);

    CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamOpen(stream);

    timeoutTimer = [[NSTimer
                     scheduledTimerWithTimeInterval:TWITTER_IMAGE_URL_CLIENT_TIMEOUT
                     target:self
                     selector:@selector(onTimeout:)
                     userInfo:nil
                     repeats:NO] retain];

    [[NSRunLoop currentRunLoop] addTimer:timeoutTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)getResultCode
{
    if (stream) {
        CFHTTPMessageRef reply = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
        if (reply) {
            int code = CFHTTPMessageGetResponseStatusCode(reply);
            if (300 <= code && code < 400) {
                NSString* location = (NSString*)CFHTTPMessageCopyHeaderFieldValue(reply, CFSTR("Location"));
                if (location) {
                    if ([delegate respondsToSelector:@selector(twitterImageURLClient:didGetImageURL:)]) {
                        [delegate twitterImageURLClient:self didGetImageURL:location];
                    }
                    [location release];
                }
                else {
                    NSError* error = (NSError*)CFReadStreamCopyError(stream);
                    if ([delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                        [delegate twitterImageURLClient:self didFailWithError:[error localizedDescription]];
                    }
                    [error release];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                    [delegate twitterImageURLClient:self didFailWithError:@"Not short URL"];
                }
            }

            CFRelease(reply);
        }
        else {
            NSError* error = (NSError*)CFReadStreamCopyError(stream);
            if ([delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                [delegate twitterImageURLClient:self didFailWithError:[error localizedDescription]];
            }
            [error release];
        }
    }

    [self cancel];
}

- (void)onTimeout:(id)sender
{
    [self cancel];

    if ([delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
        [delegate twitterImageURLClient:self didFailWithError:@"Timed out"];
    }
}

@end
