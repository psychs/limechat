// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface SheetBase : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) NSWindow* window;

@property (nonatomic) IBOutlet NSWindow* sheet;
@property (nonatomic) IBOutlet NSButton* okButton;
@property (nonatomic) IBOutlet NSButton* cancelButton;

- (void)startSheet;
- (void)endSheet;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

@end
