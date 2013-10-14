// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "ListView.h"
#import "OtherTheme.h"


@interface MemberListView : ListView

@property (nonatomic, weak) id dropDelegate;
@property (nonatomic) OtherTheme* theme;

- (void)themeChanged;

@end


@interface NSObject (MemberListView)
- (void)memberListViewKeyDown:(NSEvent*)e;
- (void)memberListViewDropFiles:(NSArray*)files row:(NSNumber*)row;
@end
