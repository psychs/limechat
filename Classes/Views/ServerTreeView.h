// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "TreeView.h"
#import "OtherTheme.h"


@interface ServerTreeView : TreeView

@property (nonatomic, weak) id responderDelegate;
@property (nonatomic) OtherTheme* theme;

- (void)themeChanged;

@end


@interface NSObject (ServerTreeViewDelegate)
- (void)serverTreeViewAcceptsFirstResponder;
@end
