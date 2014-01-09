// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogController.h"
#import "Preferences.h"
#import "LogRenderer.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "NSStringHelper.h"
#import "NSLocaleHelper.h"
#import "ImageURLParser.h"
#import "ImageDownloadManager.h"
#import "TwitterAvatarURLManager.h"
#import "LCFSystemInfo.h"


#define BOTTOM_EPSILON          20
#define INLINE_IMAGE_MAX_SIZE   (1024 * 1024)


@interface NSScrollView (NSScrollViewCompatibility)
- (void)setAllowsHorizontalScrolling:(BOOL)value;
@end

@interface WebView (Private)
- (void)setBackgroundColor:(NSColor *)color;
@end


@implementation LogController
{
    LogPolicy* _policy;
    LogScriptEventSink* _sink;
    MarkedScroller* _scroller;
    WebViewAutoScroll* _autoScroller;

    BOOL _becameVisible;
    BOOL _bottom;
    BOOL _movingToBottom;
    NSMutableArray* _lines;
    int _lineNumber;
    int _count;
    BOOL _needsLimitNumberOfLines;
    BOOL _loaded;
    NSMutableArray* _highlightedLineNumbers;
    int _loadingImages;
    NSString* _prevNickInfo;
    NSString* _html;
    BOOL _scrollBottom;
    int _scrollTop;
    NSMutableSet *_fetchingAvatarScreenNames;
}

- (id)init
{
    self = [super init];
    if (self) {
        _bottom = YES;
        _maxLines = 300;
        _lines = [NSMutableArray new];
        _highlightedLineNumbers = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (void)setMaxLines:(int)value
{
    if (_maxLines == value) return;
    _maxLines = value;

    if (!_loaded) return;

    if (_maxLines > 0 && _count > _maxLines) {
        [self savePosition];
        [self setNeedsLimitNumberOfLines];
        [self restorePosition];
    }
}

#pragma mark - Utilities

- (void)setUp
{
    _loaded = NO;

    _policy = [LogPolicy new];
    _policy.menuController = [_world menuController];
    _policy.menu = _menu;
    _policy.urlMenu = _urlMenu;
    _policy.addrMenu = _addrMenu;
    _policy.chanMenu = _chanMenu;
    _policy.memberMenu = _memberMenu;

    _sink = [LogScriptEventSink new];
    _sink.owner = self;
    _sink.policy = _policy;

    [_view removeFromSuperview];
    _view = [[LogView alloc] initWithFrame:NSZeroRect];
    if ([_view respondsToSelector:@selector(setBackgroundColor:)]) {
        [_view setBackgroundColor:_initialBackgroundColor];
    }
    _view.frameLoadDelegate = self;
    _view.UIDelegate = _policy;
    _view.policyDelegate = _policy;
    _view.resourceLoadDelegate = self;
    _view.keyDelegate = self;
    _view.resizeDelegate = self;
    _view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [[_view mainFrame] loadHTMLString:[self initialDocument] baseURL:_theme.log.baseUrl];
}

- (void)notifyDidBecomeVisible
{
    if (!_becameVisible) {
        _becameVisible = YES;
        [self moveToBottom];
    }
}

- (void)moveToTop
{
    if (!_loaded) return;
    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    [body setValue:@0 forKey:@"scrollTop"];
}

- (void)moveToBottom
{
    _movingToBottom = NO;

    if (!_loaded) return;
    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    [body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
}

- (BOOL)viewingBottom
{
    if (!_loaded) return YES;
    if (_movingToBottom) return YES;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return YES;
    DOMHTMLElement* body = [doc body];
    int viewHeight = _view.frame.size.height;
    int height = [[body valueForKey:@"scrollHeight"] intValue];
    int top = [[body valueForKey:@"scrollTop"] intValue];

    if (viewHeight == 0) return YES;
    return top + viewHeight >= height - BOTTOM_EPSILON;
}

- (void)savePosition
{
    if (_loadingImages == 0) {
        _bottom = [self viewingBottom];
    }
}

- (void)restorePosition
{
    /*
     if (bottom) {
     [self moveToBottom];
     }
     */
}

- (void)restorePositionWithDelay
{
    /*
     if (bottom) {
     if (!movingToBottom) {
     movingToBottom = YES;
     [self performSelector:@selector(moveToBottom) withObject:nil afterDelay:0];
     }
     }
     */
}

- (void)mark
{
    if (!_loaded) return;

    [self savePosition];
    [self unmark];

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    DOMHTMLElement* e = (DOMHTMLElement*)[doc createElement:@"hr"];
    [e setAttribute:@"id" value:@"mark"];
    [body appendChild:e];
    ++_count;

    [self restorePosition];
}

- (void)unmark
{
    if (!_loaded) return;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* e = (DOMHTMLElement*)[doc getElementById:@"mark"];
    if (e) {
        [[doc body] removeChild:e];
        --_count;
    }
}

- (void)goToMark
{
    if (!_loaded) return;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
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
        [[doc body] setValue:@(y - 20) forKey:@"scrollTop"];
    }
}

- (void)reloadTheme
{
    if (!_loaded) return;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    if (!body) return;

    _html = [body innerHTML];
    _scrollBottom = [self viewingBottom];
    _scrollTop = [[body valueForKey:@"scrollTop"] intValue];

    [[_view mainFrame] loadHTMLString:[self initialDocument] baseURL:_theme.log.baseUrl];
    [_scroller setNeedsDisplay];
}

- (void)clear
{
    if (!_loaded) return;

    _html = nil;
    _loaded = NO;

    [[_view mainFrame] loadHTMLString:[self initialDocument] baseURL:_theme.log.baseUrl];
    [_scroller setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
    [self savePosition];

    if (bigger) {
        [_view makeTextLarger:nil];
    }
    else {
        [_view makeTextSmaller:nil];
    }

    [self restorePosition];
}

- (void)expandImage:(NSString*)url lineNumber:(int)aLineNumber imageIndex:(int)imageIndex contentLength:(long long)contentLength contentType:(NSString*)contentType
{
    if (!_loaded) return;
    
    if (![ImageURLParser isImageContent:contentType]) {
        LOG(@"Ignore non-image image URL: %@ (%@)", url, contentType);
        return;
    }

    if (contentLength > INLINE_IMAGE_MAX_SIZE) {
        LOG(@"Ignore too big image: %@ (%qi bytes)", url, contentLength);
        return;
    }

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;

    NSString* lineIdStr = [NSString stringWithFormat:@"line%d", aLineNumber];
    DOMHTMLElement* lineElement = (DOMHTMLElement*)[doc getElementById:lineIdStr];
    if (lineElement) {
        DOMHTMLElement* messageTag = nil;

        DOMNodeList* nodeList = [lineElement childNodes];
        int nodeCount = [nodeList length];
        for (int i=0; i<nodeCount; ++i) {
            DOMHTMLElement* node = (DOMHTMLElement*)[nodeList item:i];
            if ([node isKindOfClass:[DOMHTMLElement class]]) {
                NSString* klass = [node className];
                if ([klass isEqualToString:@"message"]) {
                    messageTag = node;
                    break;
                }
            }
        }

        if (messageTag) {
            DOMElement* beforeTag = nil;

            DOMNodeList* nodeList = [messageTag childNodes];
            int nodeCount = [nodeList length];
            for (int i=0; i<nodeCount; ++i) {
                DOMHTMLElement* node = (DOMHTMLElement*)[nodeList item:i];
                if ([node isKindOfClass:[DOMHTMLBRElement class]]) {
                    beforeTag = node;
                }
                else if ([node isKindOfClass:[DOMHTMLAnchorElement class]]) {
                    if ([node hasAttribute:@"imageindex"]) {
                        NSString* indexStr = [node getAttribute:@"imageindex"];
                        int index = [indexStr intValue];
                        if (index < imageIndex) {
                            beforeTag = node;
                        }
                    }
                }
            }

            if (!beforeTag) {
                DOMElement* brTag = [doc createElement:@"br"];
                [messageTag appendChild:brTag];
                beforeTag = brTag;
            }

            [self savePosition];

            DOMHTMLElement* imageAnchorTag = (DOMHTMLElement*)[doc createElement:@"a"];
            [imageAnchorTag setAttribute:@"href" value:url];
            [imageAnchorTag setAttribute:@"imageindex" value:[NSString stringWithFormat:@"%d", imageIndex]];

            NSString* imageAnchorTagContent = [NSString stringWithFormat:@"<img src=\"%@\" class=\"inlineimage\"/>", url];
            [imageAnchorTag setInnerHTML:imageAnchorTagContent];

            DOMElement* after = [beforeTag nextElementSibling];
            if (after) {
                [messageTag insertBefore:imageAnchorTag refChild:after];
            }
            else {
                [messageTag appendChild:imageAnchorTag];
            }

            [self restorePositionWithDelay];
        }
    }
}

- (void)replaceAvatarPlaceholderWithScreenName:(NSString*)screenName imageURL:(NSString*)imageURL
{
    if (!_loaded || !screenName.length || !imageURL.length) return;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;

    NSString* placeholderClassName = [NSString stringWithFormat:@"placeholder_%@", tagEscape(screenName)];
    DOMNodeList* placeholderNodes = (DOMNodeList*)[doc getElementsByClassName:placeholderClassName];
    if (!placeholderNodes) {
        return;
    }

    int placeholderCount = placeholderNodes.length;
    for (int i=0; i<placeholderCount; i++) {
        DOMElement* placeholderElement = (DOMElement*)[placeholderNodes item:i];
        DOMElement* parent = [placeholderElement parentElement];

        DOMHTMLElement* imageTag = (DOMHTMLElement*)[doc createElement:@"img"];
        [imageTag setAttribute:@"class" value:@"avatar"];
        [imageTag setAttribute:@"src" value:imageURL];

        [parent replaceChild:imageTag oldChild:placeholderElement];
    }
}

- (void)limitNumberOfLines
{
    _needsLimitNumberOfLines = NO;

    int n = _count - _maxLines;
    if (!_loaded || n <= 0 || _count <= 0) return;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    DOMNodeList* nodeList = [body childNodes];

    BOOL viewingBottom = [self viewingBottom];

    // calculate scroll delta
    int top = 0;
    int delta = 0;
    if (!viewingBottom) {
        // remeber scroll top
        top = [[body valueForKey:@"scrollTop"] intValue];

        if (n < [nodeList length]) {
            DOMHTMLElement* firstNode = (DOMHTMLElement*)[nodeList item:0];
            DOMHTMLElement* node = (DOMHTMLElement*)[nodeList item:n];
            if ([node isKindOfClass:[DOMHTMLHRElement class]]) {
                DOMHTMLElement* nextSibling = (DOMHTMLElement*)[node nextSibling];
                if (nextSibling) {
                    node = nextSibling;
                }
            }
            if (node) {
                delta = [[node valueForKey:@"offsetTop"] intValue] - [[firstNode valueForKey:@"offsetTop"] intValue];
            }
        }
    }

    // remove lines
    //
    // note:
    //   removing from the tail is around 6x faster
    //
    for (int i=n-1; i>=0; --i) {
        DOMHTMLElement* node = (DOMHTMLElement*)[nodeList item:i];
        [body removeChild:node];
    }

    if (!viewingBottom) {
        // scroll back by delta
        if (delta > 0) {
            [body setValue:@(top - delta) forKey:@"scrollTop"];
        }
    }

    // updating highlighted line numbers
    if (_highlightedLineNumbers.count > 0) {
        DOMNodeList* nodeList = [body childNodes];
        if (nodeList.length) {
            DOMHTMLElement* firstNode = (DOMHTMLElement*)[nodeList item:0];
            if (firstNode) {
                NSString* lineId = [firstNode valueForKey:@"id"];
                if (lineId && lineId.length > 4) {
                    NSString* lineNumStr = [lineId substringFromIndex:4];	// 4 is length of "line"
                    int lineNum = [lineNumStr intValue];
                    while (_highlightedLineNumbers.count) {
                        int i = [[_highlightedLineNumbers objectAtIndex:0] intValue];
                        if (lineNum <= i) break;
                        [_highlightedLineNumbers removeObjectAtIndex:0];
                    }
                }
            }
        }
        else {
            [_highlightedLineNumbers removeAllObjects];
        }
    }
    else {
        [_highlightedLineNumbers removeAllObjects];
    }

    _count -= n;
    if (_count < 0) _count = 0;

    [_scroller setNeedsDisplay];
}

- (void)setNeedsLimitNumberOfLines
{
    if (_needsLimitNumberOfLines) return;

    _needsLimitNumberOfLines = YES;
    [self performSelector:@selector(limitNumberOfLines) withObject:nil afterDelay:0];
}

- (BOOL)print:(LogLine*)line
{
    BOOL key = NO;
    NSArray* urlRanges = nil;

    if (![LCFSystemInfo isMarvericksOrLater]) {
        line.body = [line.body lcf_stringByRemovingCrashingSequences];
    }

    NSString* body = [LogRenderer renderBody:line.body
                                    keywords:line.keywords
                                excludeWords:line.excludeWords
                          highlightWholeLine:[Preferences keywordWholeLine]
                              exactWordMatch:[Preferences keywordMatchingMethod] == KEYWORD_MATCH_EXACT
                                 highlighted:&key
                                   URLRanges:&urlRanges];

    if (!_loaded) {
        [_lines addObject:line];
        return key;
    }

    NSMutableString* s = [NSMutableString string];
    if (line.time) [s appendFormat:@"<span class=\"time\">%@</span>", logEscape(line.time)];
    if (line.place) [s appendFormat:@"<span class=\"place\">%@</span>", logEscape(line.place)];
    if (line.nick) {
        if (line.useAvatar && line.nickInfo) {
            NSString* screenName = line.nickInfo;
            TwitterAvatarURLManager* avatarManager = [TwitterAvatarURLManager instance];
            NSString* avatarImageURL = [avatarManager imageURLForTwitterScreenName:screenName];
            if (!avatarImageURL) {
                [avatarManager fetchImageURLForTwitterScreenName:screenName];
                if (!_fetchingAvatarScreenNames) {
                    _fetchingAvatarScreenNames = [NSMutableSet new];
                }
                if (![_fetchingAvatarScreenNames containsObject:screenName]) {
                    [_fetchingAvatarScreenNames addObject:screenName];
                    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
                    [nc addObserver:self selector:@selector(twitterAvatarURLManagerDidGetImageURL:) name:TwitterAvatarURLManagerDidGetImageURLNotification object:screenName];
                }
            }

            NSString* escapedNick = tagEscape(line.nickInfo);
            if (avatarImageURL) {
                [s appendFormat:@"<img class=\"avatar\" src=\"%@\"/>", tagEscape(avatarImageURL)];
            }
            else {
                [s appendFormat:@"<span class=\"avatar_placeholder placeholder_%@\"/></span>", escapedNick];
            }
        }
        [s appendFormat:@"<span class=\"sender\" _type=\"%@\"", [LogLine memberTypeString:line.memberType]];
        if (!_console) [s appendString:@" oncontextmenu=\"on_nick()\""];
        [s appendFormat:@" identified=\"%@\"", line.identified ? @"true" : @"false"];
        if (line.memberType == MEMBER_TYPE_NORMAL) [s appendFormat:@" colornumber=\"%d\"", line.nickColorNumber];
        if (line.nickInfo) [s appendFormat:@" first=\"%@\"", [line.nickInfo isEqualToString:_prevNickInfo] ? @"false" : @"true"];
        [s appendFormat:@">%@</span>", logEscape(line.nick)];
    }

    LogLineType type = line.lineType;
    NSString* lineTypeString = [LogLine lineTypeString:type];
    BOOL isText = type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_NOTICE || type == LINE_TYPE_ACTION;

    [s appendFormat:@"<span class=\"message\" _type=\"%@\">%@", lineTypeString, body];
    if (isText && !_console && urlRanges.count && [Preferences showInlineImages]) {
        //
        // expand image URLs
        //
        BOOL showInlineImage = NO;
        int imageIndex = 0;

        for (NSValue* rangeValue in urlRanges) {
            NSString* url = [line.body substringWithRange:[rangeValue rangeValue]];

            BOOL isFileURL = NO;
            BOOL checkingSize = NO;

            if ([ImageURLParser isImageFileURL:url]) {
                isFileURL = YES;
                if (![url hasPrefix:@"http://gyazo.com/"]) {
                    checkingSize = YES;
                    [[ImageDownloadManager instance] checkImageSize:url client:_client channel:_channel lineNumber:_lineNumber imageIndex:imageIndex];
                }
            }

            if (!checkingSize) {
                NSString* imageUrl = nil;
                if (isFileURL) {
                    imageUrl = url;
                }
                else {
                    imageUrl = [ImageURLParser serviceImageURLForURL:url];
                }

                if (imageUrl) {
                    if (!showInlineImage) {
                        [s appendString:@"<br/>"];
                    }
                    showInlineImage = YES;
                    [s appendFormat:@"<a href=\"%@\" imageindex=\"%d\"><img src=\"%@\" class=\"inlineimage\"/></a>", url, imageIndex, imageUrl];
                }
            }
            ++imageIndex;
        }
    }
    [s appendString:@"</span>"];

    NSString* klass = isText ? @"line text" : @"line event";

    NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
    [attrs setObject:(_lineNumber % 2 == 0 ? @"even" : @"odd") forKey:@"alternate"];
    [attrs setObject:klass forKey:@"class"];
    [attrs setObject:[LogLine lineTypeString:type] forKey:@"_type"];
    [attrs setObject:(key ? @"true" : @"false") forKey:@"highlight"];
    if (line.nickInfo) {
        [attrs setObject:line.nickInfo forKey:@"nick"];
    }
    if (_console && line.clickInfo) {
        [attrs setObject:line.clickInfo forKey:@"clickinfo"];
        [attrs setObject:@"on_dblclick()" forKey:@"ondblclick"];
    }

    [self writeLine:s attributes:attrs];

    //
    // remember nick info
    //
    _prevNickInfo = line.nickInfo;

    return key;
}

- (void)writeLine:(NSString*)aHtml attributes:(NSDictionary*)attrs
{
    [self savePosition];

    int currentLineNumber = _lineNumber;
    ++_lineNumber;
    ++_count;

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (!doc) return;
    DOMHTMLElement* body = [doc body];
    DOMHTMLElement* div = (DOMHTMLElement*)[doc createElement:@"div"];
    [div setInnerHTML:aHtml];

    for (NSString* key in attrs) {
        NSString* value = [attrs objectForKey:key];
        [div setAttribute:key value:value];
    }
    [div setAttribute:@"id" value:[NSString stringWithFormat:@"line%d", currentLineNumber]];
    [body appendChild:div];

    if (_maxLines > 0 && _count > _maxLines) {
        [self setNeedsLimitNumberOfLines];
    }

    if ([[attrs objectForKey:@"highlight"] isEqualToString:@"true"]) {
        [_highlightedLineNumbers addObject:@(currentLineNumber)];
    }

    if (_scroller) {
        [_scroller updateScroller];
        [_scroller setNeedsDisplay];
    }

    [self restorePositionWithDelay];
}

- (NSString*)initialDocument
{
    NSString* bodyClass = _console ? @"console" : @"normal";
    NSMutableString* bodyAttrs = [NSMutableString string];
    if (_channel) {
        [bodyAttrs appendFormat:@"_type=\"%@\"", [_channel channelTypeString]];
        if ([_channel isChannel]) {
            [bodyAttrs appendFormat:@" channelname=\"%@\"", tagEscape([_channel name])];
        }
    }
    else if (_console) {
        [bodyAttrs appendString:@"_type=\"console\""];
    }
    else {
        [bodyAttrs appendString:@"_type=\"server\""];
    }

    NSString* style = [[_theme log] content];

    NSString* overrideStyle = nil;

    if ([Preferences themeOverrideLogFont]) {
        NSString* name = [Preferences themeLogFontName];
        double size = [Preferences themeLogFontSize] * (72.0 / 96.0);

        NSMutableString* s = [NSMutableString string];
        [s appendString:@"html, body, body[type], body.normal, body.console {"];
        [s appendFormat:@"font-family:'%@';", name];
        [s appendFormat:@"font-size:%fpt;", size];
        [s appendString:@"}"];

        overrideStyle = s;
    }

    NSMutableString* s = [NSMutableString string];

    [s appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"];
    [s appendFormat:@"<html class=\"%@\" %@>", bodyClass, bodyAttrs];
    [s appendString:
     @"<head>"
     @"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
     @"<meta http-equiv=\"Content-Script-Type\" content=\"text/javascript\">"
     @"<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">"
     ];
    [s appendFormat:@"<style>%@</style>", [self _stringByReplacingTypeAttributeSelectorsInCSSString:[self defaultCSS]]];
    if (style) [s appendFormat:@"<style><!-- %@ --></style>", [self _stringByReplacingTypeAttributeSelectorsInCSSString:style]];
    if (overrideStyle) [s appendFormat:@"<style><!-- %@ --></style>", overrideStyle];
    [s appendString:@"</head>"];
    [s appendFormat:@"<body class=\"%@\" %@></body>", bodyClass, bodyAttrs];
    [s appendString:@"</html>"];

    return s;
}

- (NSString*)defaultCSS
{
    NSString* fontFamily = @"Courier";
    int fontSize = 9;

    if ([NSLocale prefersJapaneseLanguage]) {
        fontFamily = @"Osaka-Mono";
        fontSize = 10;
    }

    NSMutableString* s = [NSMutableString string];

    [s appendString:@"html {"];
    [s appendFormat:@"font-family:'%@';", fontFamily];
    [s appendFormat:@"font-size:%dpt;", fontSize];

    [s appendString:
     @"background-color:white;"
     @"color:black;"
     @"word-wrap:break-word;"
     @"margin:0;"
     @"padding:3px 4px 10px 4px;"
     @"}"

     @"body {margin:0;padding:0}"
     @"img {border:1px solid #aaa;vertical-align:top;}"
     @"object {vertical-align:top;}"
     @"hr {margin:0.5em 2em;}"
     @".line {margin:0 -4px; padding:0 4px 1px 4px; clear:both;}"
     @".line[alternate=even] {}"
     @".line[alternate=odd] {}"
     @".line[type=action] .sender:before {"
     @"content: '• ';"
     @"white-space: nowrap;"
     @"}"

     @".inlineimage {"
     @"margin: 10px 0 15px 40px;"
     @"max-width: 200px;"
     @"max-height: 150px;"
     @"-webkit-box-shadow: 2px 2px 2px #888;"
     @"}"

     @".avatar {"
     @"display: inline;"
     @"max-width: 24px;"
     @"max-height: 24px;"
     @"margin-right: 3px;"
     @"vertical-align: middle;"
     @"}"

     @".url { word-break: break-all; }"
     @".address { text-decoration: underline; word-break: break-all; }"
     @".highlight { color: #f0f; font-weight: bold; }"
     @".time { color: #048; }"
     @".place { color: #008; }"

     @".sender[type=myself] { color: #66a; }"
     @".sender[type=normal] { color: #008; }"

     @".message[type=system] { color: #080; }"
     @".message[type=error] { color: #f00; font-weight: bold; }"
     @".message[type=reply] { color: #088; }"
     @".message[type=error_reply] { color: #f00; }"
     @".message[type=dcc_send_send] { color: #088; }"
     @".message[type=dcc_send_receive] { color: #00c; }"
     @".message[type=privmsg] {}"
     @".message[type=notice] { color: #888; }"
     @".message[type=action] {}"
     @".message[type=join] { color: #080; }"
     @".message[type=part] { color: #080; }"
     @".message[type=kick] { color: #080; }"
     @".message[type=quit] { color: #080; }"
     @".message[type=kill] { color: #080; }"
     @".message[type=nick] { color: #080; }"
     @".message[type=mode] { color: #080; }"
     @".message[type=topic] { color: #080; }"
     @".message[type=invite] { color: #080; }"
     @".message[type=wallops] { color: #080; }"
     @".message[type=debug_send] { color: #aaa; }"
     @".message[type=debug_receive] { color: #444; }"

     @".effect[color-number='0'] { color: #fff; }"
     @".effect[color-number='1'] { color: #000; }"
     @".effect[color-number='2'] { color: #008; }"
     @".effect[color-number='3'] { color: #080; }"
     @".effect[color-number='4'] { color: #f00; }"
     @".effect[color-number='5'] { color: #800; }"
     @".effect[color-number='6'] { color: #808; }"
     @".effect[color-number='7'] { color: #f80; }"
     @".effect[color-number='8'] { color: #ff0; }"
     @".effect[color-number='9'] { color: #0f0; }"
     @".effect[color-number='10'] { color: #088; }"
     @".effect[color-number='11'] { color: #0ff; }"
     @".effect[color-number='12'] { color: #00f; }"
     @".effect[color-number='13'] { color: #f0f; }"
     @".effect[color-number='14'] { color: #888; }"
     @".effect[color-number='15'] { color: #ccc; }"
     @".effect[bgcolor-number='0'] { background-color: #fff; }"
     @".effect[bgcolor-number='1'] { background-color: #000; }"
     @".effect[bgcolor-number='2'] { background-color: #008; }"
     @".effect[bgcolor-number='3'] { background-color: #080; }"
     @".effect[bgcolor-number='4'] { background-color: #f00; }"
     @".effect[bgcolor-number='5'] { background-color: #800; }"
     @".effect[bgcolor-number='6'] { background-color: #808; }"
     @".effect[bgcolor-number='7'] { background-color: #f80; }"
     @".effect[bgcolor-number='8'] { background-color: #ff0; }"
     @".effect[bgcolor-number='9'] { background-color: #0f0; }"
     @".effect[bgcolor-number='10'] { background-color: #088; }"
     @".effect[bgcolor-number='11'] { background-color: #0ff; }"
     @".effect[bgcolor-number='12'] { background-color: #00f; }"
     @".effect[bgcolor-number='13'] { background-color: #f0f; }"
     @".effect[bgcolor-number='14'] { background-color: #888; }"
     @".effect[bgcolor-number='15'] { background-color: #ccc; }"
     ];

    return s;
}

- (NSString*)_stringByReplacingTypeAttributeSelectorsInCSSString:(NSString*)inputString
{
    // On Mavericks, type selector doesn't work sometimes.
    static NSRegularExpression* re = nil;
    if (!re) {
        re = [NSRegularExpression regularExpressionWithPattern:@"\\[\\s*type\\s*([=~|\\]])" options:0 error:NULL];
    }
    return [re stringByReplacingMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length]) withTemplate:@"[_type$1"];
}

- (void)setUpScroller
{
    WebFrameView* frame = [[_view mainFrame] frameView];
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
        [scrollView setAllowsHorizontalScrolling:NO];
    }
    [[_view windowScriptObject] evaluateWebScript:@"document.body.style.overflowX='hidden';"];

    NSScroller* old = [scrollView verticalScroller];
    if (old && ![old isKindOfClass:[MarkedScroller class]]) {
        [_scroller removeFromSuperview];
        _scroller = [[MarkedScroller alloc] initWithFrame:NSMakeRect(-16, -64, 16, 64)];
        _scroller.dataSource = self;
        [_scroller setFloatValue:[old floatValue]];
        [_scroller setKnobProportion:[old knobProportion]];
        [scrollView setVerticalScroller:_scroller];
    }
}

#pragma mark - WebView Delegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [[_view windowScriptObject] setValue:_sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    _loaded = YES;
    _loadingImages = 0;
    [self setUpScroller];

    if (!_autoScroller) {
        _autoScroller = [WebViewAutoScroll new];
    }
    _autoScroller.webFrame = _view.mainFrame.frameView;
    _autoScroller.scroller = _scroller;

    if (_html) {
        DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
        if (doc) {
            DOMHTMLElement* body = [doc body];
            [body setInnerHTML:_html];
            _html = nil;

            if (_scrollBottom) {
                [self moveToBottom];
            }
            else if (_scrollTop) {
                [body setValue:@(_scrollTop) forKey:@"scrollTop"];
            }
        }
    }
    else {
        [self moveToBottom];
        _bottom = YES;
    }

    for (LogLine* line in _lines) {
        [self print:line];
    }
    [_lines removeAllObjects];

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
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

    if (_console) {
        [s appendString:
         @"function on_dblclick() {"
         @"  var t = event.target;"
         @"  while (t && !(t.tagName == 'DIV' && t.className.match(/^line /))) {"
         @"    t = t.parentNode;"
         @"  }"
         @"  if (t) {"
         @"    app.onDblClick(t.getAttribute('clickinfo'));"
         @"  }"
         @"  event.stopPropagation();"
         @"}"
         @"function on_mousedown() {"
         @"  if (app.shouldStopDoubleClick(event)) {"
         @"    event.preventDefault();"
         @"  }"
         @"  event.stopPropagation();"
         @"}"
         @"function on_url() {"
         @"  var t = event.target;"
         @"  app.setUrl(t.innerHTML);"
         @"}"
         @"function on_addr() {"
         @"  var t = event.target;"
         @"  app.setAddr(t.innerHTML);"
         @"}"
         @"document.addEventListener('mousedown', on_mousedown, false);"
         ];
    }
    else {
        [s appendString:
         @"function on_url() {"
         @"  var t = event.target;"
         @"  app.setUrl(t.innerHTML);"
         @"}"
         @"function on_addr() {"
         @"  var t = event.target;"
         @"  app.setAddr(t.innerHTML);"
         @"}"
         @"function on_nick() {"
         @"  var t = event.target;"
         @"  app.setNick(t.parentNode.getAttribute('nick'));"
         @"}"
         @"function on_chname() {"
         @"  var t = event.target;"
         @"  app.setChan(t.innerHTML);"
         @"}"
         ];
    }

    [[_view windowScriptObject] evaluateWebScript:s];

    // evaluate theme js
    if (_theme.js.content.length) {
        [[_view windowScriptObject] evaluateWebScript:_theme.js.content];
    }
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
    NSString* scheme = [[[request URL] scheme] lowercaseString];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        if (_loadingImages == 0) {
            [self savePosition];
        }
        ++_loadingImages;
        return self;
    }
    return nil;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
    if (identifier) {
        if (_loadingImages > 0) {
            --_loadingImages;
        }
        if (_loadingImages == 0) {
            [self restorePosition];
        }
    }
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;
{
    if ([[[request URL] host] hasSuffix:@"pixiv.net"]) {
        NSMutableURLRequest* req = nil;
        if ([request isKindOfClass:[NSMutableURLRequest class]]) {
            req = (NSMutableURLRequest*)request;
        }
        else {
            req = [request mutableCopy];
        }
        [req setValue:@"http://www.pixiv.net" forHTTPHeaderField:@"Referer"];
        return req;
    }
    return request;
}

#pragma mark - LogView Delegate

- (void)logViewKeyDown:(NSEvent *)e
{
    [_world logKeyDown:e];
}

- (void)logViewOnDoubleClick:(NSString*)e
{
    [_world logDoubleClick:e];
}

- (void)logViewWillResize
{
    [self savePosition];
}

- (void)logViewDidResize
{
    [self restorePosition];
}

#pragma mark - MarkedScroller Delegate

- (NSArray*)markedScrollerPositions:(MarkedScroller*)sender
{
    NSMutableArray* result = [NSMutableArray array];

    DOMHTMLDocument* doc = (DOMHTMLDocument*)[[_view mainFrame] DOMDocument];
    if (doc) {
        for (NSNumber* n in _highlightedLineNumbers) {
            NSString* key = [NSString stringWithFormat:@"line%d", [n intValue]];
            DOMHTMLElement* e = (DOMHTMLElement*)[doc getElementById:key];
            if (e) {
                int pos = [[e valueForKey:@"offsetTop"] intValue] + [[e valueForKey:@"offsetHeight"] intValue] / 2;
                [result addObject:@(pos)];
            }
        }
    }

    return result;
}

- (NSColor*)markedScrollerColor:(MarkedScroller*)sender
{
    return [[_theme other] logScrollerMarkColor];
}

#pragma mark - TwitterAvatarImageURLManager Notifications

- (void)twitterAvatarURLManagerDidGetImageURL:(NSNotification*)note
{
    NSString* screenName = [note object];
    if (screenName) {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:TwitterAvatarURLManagerDidGetImageURLNotification object:screenName];

        [_fetchingAvatarScreenNames removeObject:screenName];

        NSString* imageURL = [[TwitterAvatarURLManager instance] imageURLForTwitterScreenName:screenName];
        if (imageURL) {
            [self replaceAvatarPlaceholderWithScreenName:screenName imageURL:imageURL];
        }
    }
}

@end
