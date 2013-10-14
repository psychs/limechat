// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ListDialog.h"
#import "Preferences.h"
#import "NSDictionaryHelper.h"


@implementation ListDialog
{
    NSMutableArray* _list;
    NSMutableArray* _filteredList;
}

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ListDialog" owner:self];

        _list = [NSMutableArray new];
        _sortKey = 1;
        _sortOrder = NSOrderedDescending;
    }
    return self;
}

- (void)start
{
    [_table setDoubleAction:@selector(onJoin:)];

    [self show];
}

- (void)show
{
    if (![self.window isVisible]) {
        NSDictionary* dic = [Preferences loadWindowStateWithName:@"channel_list_window"];
        if (dic) {
            NSDictionary* win = [dic objectForKey:@"window"];
            NSArray* cols = [dic objectForKey:@"tablecols"];

            double x = [win doubleForKey:@"x"];
            double y = [win doubleForKey:@"y"];
            double w = [win doubleForKey:@"w"];
            double h = [win doubleForKey:@"h"];
            [self.window setFrame:NSMakeRect(x, y, w, h) display:NO];

            int i = 0;
            for (NSNumber* n in cols) {
                [[[_table tableColumns] objectAtIndex:i] setWidth:[n doubleValue]];
                ++i;
            }
        }
        else {
            [self.window center];
        }
    }

    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    [self.window close];
}

- (void)clear
{
    [_list removeAllObjects];
    _filteredList = nil;

    [self reloadTable];
}

- (void)addChannel:(NSString*)channel count:(int)count topic:(NSString*)topic
{
    NSArray* item = [NSArray arrayWithObjects:channel, @(count), topic, nil];

    NSString* filter = [_filterText stringValue];
    if (filter.length) {
        if (!_filteredList) {
            _filteredList = [NSMutableArray new];
        }

        if ([channel rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound
            || [topic rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self sortedInsert:item inArray:_filteredList];
        }
    }

    [self sortedInsert:item inArray:_list];
    [self reloadTable];
}

- (void)reloadTable
{
    [_table reloadData];
}

static NSInteger compareItems(NSArray* self, NSArray* other, void* context)
{
    ListDialog* dialog = (__bridge ListDialog*)context;
    int key = dialog.sortKey;
    NSComparisonResult order = dialog.sortOrder;

    NSString* mine = [self objectAtIndex:key];
    NSString* others = [other objectAtIndex:key];

    NSComparisonResult result;
    if (key == 1) {
        result = [mine compare:others];
    }
    else {
        result = [mine caseInsensitiveCompare:others];
    }

    if (order == NSOrderedDescending) {
        return - result;
    }
    else {
        return result;
    }
}

- (void)sort
{
    [_list sortUsingFunction:compareItems context:(void*)self];
}

- (void)sortedInsert:(NSArray*)item inArray:(NSMutableArray*)ary
{
    const int THRESHOLD = 5;
    int left = 0;
    int right = ary.count;

    while (right - left > THRESHOLD) {
        int pivot = (left + right) / 2;
        if (compareItems([ary objectAtIndex:pivot], item, (__bridge void*)self) == NSOrderedDescending) {
            right = pivot;
        }
        else {
            left = pivot;
        }
    }

    for (int i=left; i<right; ++i) {
        if (compareItems([ary objectAtIndex:i], item, (__bridge void*)self) == NSOrderedDescending) {
            [ary insertObject:item atIndex:i];
            return;
        }
    }

    [ary insertObject:item atIndex:right];
}

#pragma mark - Actions

- (void)onClose:(id)sender
{
    [self.window close];
}

- (void)onUpdate:(id)sender
{
    if ([_delegate respondsToSelector:@selector(listDialogOnUpdate:)]) {
        [_delegate listDialogOnUpdate:self];
    }
}

- (void)onJoin:(id)sender
{
    NSArray* ary = _list;
    NSString* filter = [_filterText stringValue];
    if (filter.length) {
        ary = _filteredList;
    }

    NSIndexSet* indexes = [_table selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        NSArray* item = [ary objectAtIndex:i];
        if ([_delegate respondsToSelector:@selector(listDialogOnJoin:channel:)]) {
            [_delegate listDialogOnJoin:self channel:[item objectAtIndex:0]];
        }
    }
}

- (void)onSearchFieldChange:(id)sender
{
    _filteredList = nil;

    NSString* filter = [_filterText stringValue];
    if (filter.length) {
        NSMutableArray* ary = [NSMutableArray new];
        for (NSArray* item in _list) {
            NSString* channel = [item objectAtIndex:0];
            NSString* topic = [item objectAtIndex:2];
            if ([channel rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound
                || [topic rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [ary addObject:item];
            }
        }
        _filteredList = ary;
    }

    [self reloadTable];
}

- (BOOL)loadWindowState
{
    NSDictionary* dic = [Preferences loadWindowStateWithName:@"channel_list_window"];
    if (!dic) return NO;

    NSDictionary* win = [dic objectForKey:@"window"];
    NSArray* cols = [dic objectForKey:@"tablecols"];

    double x = [win doubleForKey:@"x"];
    double y = [win doubleForKey:@"y"];
    double w = [win doubleForKey:@"w"];
    double h = [win doubleForKey:@"h"];
    [self.window setFrame:NSMakeRect(x, y, w, h) display:NO];

    int i = 0;
    for (NSNumber* n in cols) {
        [[[_table tableColumns] objectAtIndex:i] setWidth:[n doubleValue]];
        ++i;
    }

    return YES;
}

- (void)saveWindowState
{
    NSMutableDictionary* win = [NSMutableDictionary dictionary];
    NSRect rect = self.window.frame;
    [win setDouble:rect.origin.x forKey:@"x"];
    [win setDouble:rect.origin.y forKey:@"y"];
    [win setDouble:rect.size.width forKey:@"w"];
    [win setDouble:rect.size.height forKey:@"h"];

    NSMutableArray* cols = [NSMutableArray array];
    for (NSTableColumn* col in [_table tableColumns]) {
        [cols addObject:@(col.width)];
    }

    NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:win, @"window", cols, @"tablecols", nil];
    [Preferences saveWindowState:dic name:@"channel_list_window"];
}

#pragma mark - NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    if (_filteredList) {
        return _filteredList.count;
    }
    return _list.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray* ary = _filteredList ?: _list;
    NSArray* item = [ary objectAtIndex:row];
    NSString* col = [column identifier];

    if ([col isEqualToString:@"chname"]) {
        return [item objectAtIndex:0];
    }
    else if ([col isEqualToString:@"count"]) {
        return [item objectAtIndex:1];
    }
    else {
        return [item objectAtIndex:2];
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column
{
    int i;
    NSString* col = [column identifier];
    if ([col isEqualToString:@"chname"]) {
        i = 0;
    }
    else if ([col isEqualToString:@"count"]) {
        i = 1;
    }
    else {
        i = 2;
    }

    if (_sortKey == i) {
        _sortOrder = - _sortOrder;
    }
    else {
        _sortKey = i;
        _sortOrder = (_sortKey == 1) ? NSOrderedDescending : NSOrderedAscending;
    }

    [self sort];

    if (_filteredList) {
        [self onSearchFieldChange:nil];
    }

    [self reloadTable];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    [self saveWindowState];

    if ([_delegate respondsToSelector:@selector(listDialogWillClose:)]) {
        [_delegate listDialogWillClose:self];
    }
}

@end
