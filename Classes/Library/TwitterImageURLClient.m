// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TwitterImageURLClient.h"
#import "GTMNSString+URLArguments.h"


#define TWITTER_IMAGE_URL_CLIENT_TIMEOUT    30


static void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType type, void* userData)
{
    TwitterImageURLClient* client = (__bridge TwitterImageURLClient*)userData;

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
    return (void*)CFRetain((CFTypeRef)obj);
}

static void CFClientRelease(void* obj)
{
    CFRelease((CFTypeRef)obj);
}

static CFStringRef CFClientDescribeCopy(void* obj)
{
    return CFRetain((__bridge CFStringRef)[[(__bridge id)obj description] copy]);
}


@implementation TwitterImageURLClient
{
    CFReadStreamRef _stream;
    CFStreamClientContext _context;
    NSTimer* _timeoutTimer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _context.version = 0;
        _context.info = (__bridge void*)self;
        _context.retain = CFClientRetain;
        _context.release = CFClientRelease;
        _context.copyDescription = CFClientDescribeCopy;
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
}

- (void)cancel
{
    if (_stream) {
        CFReadStreamClose(_stream);
        CFReadStreamSetClient(_stream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(_stream);
        _stream = NULL;
    }

    if (_timeoutTimer) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

- (void)getImageURL
{
    [self cancel];

    NSString* url = [NSString stringWithFormat:@"http://api.twitter.com/1/users/profile_image?size=normal&screen_name=%@", [_screenName gtm_stringByEscapingForURLArgument]];
    NSURL* urlObj = [NSURL URLWithString:url];
    if (!urlObj) {
        if ([_delegate respondsToSelector:@selector(twitterImageURLClientDidReceiveBadURL:)]) {
            [_delegate twitterImageURLClientDidReceiveBadURL:self];
        }
        return;
    }

    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)@"HEAD", (__bridge CFURLRef)urlObj, kCFHTTPVersion1_1);
    _stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    CFRelease(request);

    CFReadStreamSetClient(_stream,
                          kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
                          readStreamEventHandler,
                          &_context);

    CFReadStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamOpen(_stream);

    _timeoutTimer = [NSTimer
                     scheduledTimerWithTimeInterval:TWITTER_IMAGE_URL_CLIENT_TIMEOUT
                     target:self
                     selector:@selector(onTimeout:)
                     userInfo:nil
                     repeats:NO];

    [[NSRunLoop currentRunLoop] addTimer:_timeoutTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)getResultCode
{
    if (_stream) {
        CFHTTPMessageRef reply = (CFHTTPMessageRef)CFReadStreamCopyProperty(_stream, kCFStreamPropertyHTTPResponseHeader);
        if (reply) {
            int code = CFHTTPMessageGetResponseStatusCode(reply);
            if (300 <= code && code < 400) {
                NSString* location = (__bridge_transfer NSString*)CFHTTPMessageCopyHeaderFieldValue(reply, CFSTR("Location"));
                if (location) {
                    if ([_delegate respondsToSelector:@selector(twitterImageURLClient:didGetImageURL:)]) {
                        [_delegate twitterImageURLClient:self didGetImageURL:location];
                    }
                }
                else {
                    NSError* error = (__bridge_transfer NSError*)CFReadStreamCopyError(_stream);
                    if ([_delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                        [_delegate twitterImageURLClient:self didFailWithError:[error localizedDescription]];
                    }
                }
            }
            else {
                if ([_delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                    [_delegate twitterImageURLClient:self didFailWithError:@"Not short URL"];
                }
            }

            CFRelease(reply);
        }
        else {
            NSError* error = (__bridge_transfer NSError*)CFReadStreamCopyError(_stream);
            if ([_delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
                [_delegate twitterImageURLClient:self didFailWithError:[error localizedDescription]];
            }
        }
    }

    [self cancel];
}

- (void)onTimeout:(id)sender
{
    [self cancel];

    if ([_delegate respondsToSelector:@selector(twitterImageURLClient:didFailWithError:)]) {
        [_delegate twitterImageURLClient:self didFailWithError:@"Timed out"];
    }
}

@end
