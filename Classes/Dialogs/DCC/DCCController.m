// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DCCController.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "Preferences.h"
#import "DCCReceiver.h"
#import "DCCSender.h"
#import "DCCFileTransferCell.h"
#import "TableProgressIndicator.h"
#import "SoundPlayer.h"
#import "NSDictionaryHelper.h"


#define TIMER_INTERVAL  1


@implementation DCCController
{
    BOOL _loaded;
    NSMutableArray* _receivers;
    NSMutableArray* _senders;

    Timer* _timer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _receivers = [NSMutableArray new];
        _senders = [NSMutableArray new];

        _timer = [Timer new];
        _timer.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_timer stop];
}

- (void)show:(BOOL)key
{
    if (!_loaded) {
        _loaded = YES;
        [[NSBundle mainBundle] loadNibNamed:@"DCCDialog" owner:self topLevelObjects:NULL];
        [_splitter setFixedViewIndex:1];

        DCCFileTransferCell* senderCell = [DCCFileTransferCell new];
        [[[_senderTable tableColumns] objectAtIndex:0] setDataCell:senderCell];

        DCCFileTransferCell* receiverCell = [DCCFileTransferCell new];
        [[[_receiverTable tableColumns] objectAtIndex:0] setDataCell:receiverCell];

        for (DCCReceiver* e in _receivers) {
            if (e.status == DCC_RECEIVING) {
                [self dccReceiveOnOpen:e];
            }
        }

        for (DCCSender* e in _senders) {
            if (e.status == DCC_SENDING) {
                [self dccSenderOnConnect:e];
            }
        }
    }

    if (![self.window isVisible]) {
        [self loadWindowState];
    }

    if (key) {
        [self.window makeKeyAndOrderFront:nil];
    }
    else {
        [self.window orderFront:nil];
    }

    [self reloadReceiverTable];
    [self reloadSenderTable];
}

- (void)close
{
    if (!_loaded) return;

    [self.window close];
}

- (void)terminate
{
    [self close];
}

- (void)nickChanged:(NSString*)nick toNick:(NSString*)toNick client:(IRCClient*)client
{
    int uid = client.uid;
    BOOL found = NO;

    for (DCCReceiver* e in _receivers) {
        if (e.uid == uid && [e.peerNick isEqualToString:nick]) {
            e.peerNick = toNick;
            found = YES;
        }
    }

    for (DCCSender* e in _senders) {
        if (e.uid == uid && [e.peerNick isEqualToString:nick]) {
            e.peerNick = toNick;
            found = YES;
        }
    }

    if (found) {
        [self reloadReceiverTable];
        [self reloadSenderTable];
    }
}

- (void)addReceiverWithUID:(int)uid nick:(NSString*)nick host:(NSString*)host port:(int)port path:(NSString*)path fileName:(NSString*)fileName size:(long long)size
{
    DCCReceiver* c = [DCCReceiver new];
    c.delegate = self;
    c.uid = uid;
    c.peerNick = nick;
    c.host = host;
    c.port = port;
    c.path = path;
    c.fileName = fileName;
    c.size = size;
    [_receivers insertObject:c atIndex:0];

    if ([Preferences dccAction] == DCC_AUTO_ACCEPT) {
        [c open];
    }
    [self show:NO];
}

- (void)addSenderWithUID:(int)uid nick:(NSString*)nick fileName:(NSString*)fileName autoOpen:(BOOL)autoOpen
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDictionary* attr = [fm attributesOfItemAtPath:fileName error:NULL];
    if (!attr) return;
    NSNumber* sizeNum = [attr objectForKey:NSFileSize];
    long long size = [sizeNum longLongValue];

    if (!size) return;

    DCCSender* c = [DCCSender new];
    c.delegate = self;
    c.uid = uid;
    c.peerNick = nick;
    c.fullFileName = fileName;
    [_senders insertObject:c atIndex:0];

    IRCClient* u = [_world findClientById:uid];
    if (!u || !u.myAddress) {
        [c setAddressError];
        return;
    }

    if (autoOpen) {
        [c open];
    }

    [self reloadSenderTable];
    [self show:YES];
}

- (int)countReceivingItems
{
    int i = 0;
    for (DCCReceiver* e in _receivers) {
        if (e.status == DCC_RECEIVING) {
            ++i;
        }
    }
    return i;
}

- (int)countSendingItems
{
    int i = 0;
    for (DCCSender* e in _senders) {
        if (e.status == DCC_SENDING) {
            ++i;
        }
    }
    return i;
}

- (void)reloadReceiverTable
{
    [_receiverTable reloadData];
    [self updateClearButton];
}

- (void)reloadSenderTable
{
    [_senderTable reloadData];
    [self updateClearButton];
}

- (void)updateClearButton
{
    BOOL enabled = NO;

    for (int i=_receivers.count-1; i>=0; --i) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
            enabled = YES;
            break;
        }
    }

    if (!enabled) {
        for (int i=_senders.count-1; i>=0; --i) {
            DCCSender* e = [_senders objectAtIndex:i];
            if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
                enabled = YES;
                break;
            }
        }
    }

    [_clearButton setEnabled:enabled];
}

- (void)loadWindowState
{
    NSDictionary* dic = [Preferences loadWindowStateWithName:@"dcc_window"];
    if (dic) {
        int x = [dic intForKey:@"x"];
        int y = [dic intForKey:@"y"];
        int w = [dic intForKey:@"w"];
        int h = [dic intForKey:@"h"];
        NSRect r = NSMakeRect(x, y, w, h);
        [self.window setFrame:r display:NO];
        [_splitter setPosition:[dic intForKey:@"split"]];
    }
    else {
        [self.window setFrame:NSMakeRect(0, 0, 350, 300) display:NO];
        [self.window center];
        [_splitter setPosition:100];
    }
}

- (void)saveWindowState
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    NSRect rect = self.window.frame;
    [dic setInt:rect.origin.x forKey:@"x"];
    [dic setInt:rect.origin.y forKey:@"y"];
    [dic setInt:rect.size.width forKey:@"w"];
    [dic setInt:rect.size.height forKey:@"h"];
    [dic setInt:_splitter.position forKey:@"split"];

    [Preferences saveWindowState:dic name:@"dcc_window"];
    [Preferences sync];
}

- (void)destroyReceiverAtIndex:(int)i
{
    DCCReceiver* e = [_receivers objectAtIndex:i];
    e.delegate = nil;
    [e close];

    NSProgressIndicator* bar = e.progressBar;
    if (bar) {
        [bar removeFromSuperview];
    }
    [_receivers removeObjectAtIndex:i];
}

- (void)destroySenderAtIndex:(int)i
{
    DCCSender* e = [_senders objectAtIndex:i];
    e.delegate = nil;
    [e close];

    NSProgressIndicator* bar = e.progressBar;
    if (bar) {
        [bar removeFromSuperview];
    }
    [_senders removeObjectAtIndex:i];
}

#pragma mark - Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    NSInteger tag = item.tag;

    if (tag < 3100) {
        if (![_receiverTable countSelectedRows]) return NO;

        NSMutableArray* sel = [NSMutableArray array];
        NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
        for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
            [sel addObject:[_receivers objectAtIndex:i]];
        }

        switch (tag) {
            case 3001:	// start receiver
                for (DCCReceiver* e in sel) {
                    if (e.status == DCC_INIT || e.status == DCC_ERROR) {
                        return YES;
                    }
                }
                return NO;
            case 3002:	// resume receiver (not implemented)
                return YES;
            case 3003:	// stop receiver
                for (DCCReceiver* e in sel) {
                    if (e.status == DCC_CONNECTING || e.status == DCC_RECEIVING) {
                        return YES;
                    }
                }
                return NO;
            case 3004:	// delete receiver
                return YES;
            case 3005:	// open file
                for (DCCReceiver* e in sel) {
                    if (e.status == DCC_COMPLETE) {
                        return YES;
                    }
                }
                return NO;
            case 3006:	// reveal in finder
                for (DCCReceiver* e in sel) {
                    if (e.status == DCC_COMPLETE || e.status == DCC_ERROR) {
                        return YES;
                    }
                }
                return NO;
        }
    }
    else {
        if (![_senderTable countSelectedRows]) return NO;

        NSMutableArray* sel = [NSMutableArray array];
        NSIndexSet* indexes = [_senderTable selectedRowIndexes];
        for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
            [sel addObject:[_senders objectAtIndex:i]];
        }

        switch (tag) {
            case 3101:	// start sender
                for (DCCSender* e in sel) {
                    if (e.status == DCC_INIT || e.status == DCC_ERROR || e.status == DCC_STOP) {
                        return YES;
                    }
                }
                return NO;
            case 3102:	// stop sender
                for (DCCSender* e in sel) {
                    if (e.status == DCC_LISTENING || e.status == DCC_SENDING) {
                        return YES;
                    }
                }
                return NO;
            case 3103:	// delete sender
                return YES;
        }
    }

    return NO;
}

- (void)clear:(id)sender
{
    for (int i=_receivers.count-1; i>=0; --i) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
            [self destroyReceiverAtIndex:i];
        }
    }

    for (int i=_senders.count-1; i>=0; --i) {
        DCCSender* e = [_senders objectAtIndex:i];
        if (e.status == DCC_ERROR || e.status == DCC_COMPLETE || e.status == DCC_STOP) {
            [self destroySenderAtIndex:i];
        }
    }

    [self reloadReceiverTable];
    [self reloadSenderTable];
}

- (void)startReceiver:(id)sender
{
    NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        [e open];
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)stopReceiver:(id)sender
{
    NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        [e close];
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)deleteReceiver:(id)sender
{
    NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
    for (NSUInteger i=[indexes lastIndex]; i!=NSNotFound; i=[indexes indexLessThanIndex:i]) {
        [self destroyReceiverAtIndex:i];
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)openReceiver:(id)sender
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];

    NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        [ws openFile:e.downloadFileName];
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)revealReceivedFileInFinder:(id)sender
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];

    NSIndexSet* indexes = [_receiverTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCReceiver* e = [_receivers objectAtIndex:i];
        [ws selectFile:e.downloadFileName inFileViewerRootedAtPath:nil];
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)startSender:(id)sender
{
    NSIndexSet* indexes = [_senderTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCSender* e = [_senders objectAtIndex:i];
        [e open];
    }

    [self reloadSenderTable];
    [self updateTimer];
}

- (void)stopSender:(id)sender
{
    NSIndexSet* indexes = [_senderTable selectedRowIndexes];
    for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
        DCCSender* e = [_senders objectAtIndex:i];
        [e close];
    }

    [self reloadSenderTable];
    [self updateTimer];
}

- (void)deleteSender:(id)sender
{
    NSIndexSet* indexes = [_senderTable selectedRowIndexes];
    for (NSUInteger i=[indexes lastIndex]; i!=NSNotFound; i=[indexes indexLessThanIndex:i]) {
        [self destroySenderAtIndex:i];
    }

    [self reloadSenderTable];
    [self updateTimer];
}

#pragma mark - DCCReceiver Delegate

- (void)removeControlsFromReceiver:(DCCReceiver*)receiver
{
    if (receiver.progressBar) {
        [receiver.progressBar removeFromSuperview];
        receiver.progressBar = nil;
    }
}

- (void)dccReceiveOnOpen:(DCCReceiver*)sender
{
    if (!_loaded) return;

    if (!sender.progressBar) {
        TableProgressIndicator* bar = [TableProgressIndicator new];
        [bar setIndeterminate:NO];
        [bar setMinValue:0];
        [bar setMaxValue:sender.size];
        [bar setDoubleValue:sender.processedSize];
        [_receiverTable addSubview:bar];
        sender.progressBar = bar;
    }

    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)dccReceiveOnClose:(DCCReceiver*)sender
{
    if (!_loaded) return;

    [self removeControlsFromReceiver:sender];
    [self reloadReceiverTable];
    [self updateTimer];
}

- (void)dccReceiveOnError:(DCCReceiver*)sender
{
    if (!_loaded) return;

    [self removeControlsFromReceiver:sender];
    [self reloadReceiverTable];
    [self updateTimer];

    [_world sendUserNotification:USER_NOTIFICATION_FILE_RECEIVE_ERROR title:sender.peerNick desc:sender.fileName context:nil];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_FILE_RECEIVE_ERROR]];
}

- (void)dccReceiveOnComplete:(DCCReceiver*)sender
{
    if (!_loaded) return;

    [self removeControlsFromReceiver:sender];
    [self reloadReceiverTable];
    [self updateTimer];

    [_world sendUserNotification:USER_NOTIFICATION_FILE_RECEIVE_SUCCESS title:sender.peerNick desc:sender.fileName context:nil];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_FILE_RECEIVE_SUCCESS]];
}

#pragma mark - DCCSender Delegate

- (void)removeControlsFromSender:(DCCSender*)sender
{
    if (sender.progressBar) {
        [sender.progressBar removeFromSuperview];
        sender.progressBar = nil;
    }
}

- (void)dccSenderOnListen:(DCCSender*)sender
{
    IRCClient* u = [_world findClientById:sender.uid];
    if (!u) return;

    [u sendFile:sender.peerNick port:sender.port fileName:sender.fileName size:sender.size];

    if (!_loaded) return;

    [self reloadSenderTable];
    [self updateTimer];
}

- (void)dccSenderOnConnect:(DCCSender*)sender
{
    if (!_loaded) return;

    if (!sender.progressBar) {
        TableProgressIndicator* bar = [TableProgressIndicator new];
        [bar setIndeterminate:NO];
        [bar setMinValue:0];
        [bar setMaxValue:sender.size];
        [bar setDoubleValue:sender.processedSize];
        [_senderTable addSubview:bar];
        sender.progressBar = bar;
    }

    [self reloadSenderTable];
    [self updateTimer];
}

- (void)dccSenderOnClose:(DCCSender*)sender
{
    if (!_loaded) return;

    [self removeControlsFromSender:sender];
    [self reloadSenderTable];
    [self updateTimer];
}

- (void)dccSenderOnError:(DCCSender*)sender
{
    if (!_loaded) return;

    [self removeControlsFromSender:sender];
    [self reloadSenderTable];
    [self updateTimer];

    [_world sendUserNotification:USER_NOTIFICATION_FILE_SEND_ERROR title:sender.peerNick desc:sender.fileName context:nil];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_FILE_SEND_ERROR]];
}

- (void)dccSenderOnComplete:(DCCSender*)sender
{
    if (!_loaded) return;

    [self removeControlsFromSender:sender];
    [self reloadSenderTable];
    [self updateTimer];

    [_world sendUserNotification:USER_NOTIFICATION_FILE_SEND_SUCCESS title:sender.peerNick desc:sender.fileName context:nil];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_FILE_SEND_SUCCESS]];
}

#pragma mark - NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    if (sender == _senderTable) {
        return _senders.count;
    }
    else {
        return _receivers.count;
    }
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(DCCFileTransferCell*)c forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    if (sender == _senderTable) {
        if (row < 0 || _senders.count <= row) return;

        DCCSender* e = [_senders objectAtIndex:row];
        double speed = e.speed;

        c.sendingItem = YES;
        c.stringValue = e.fileName;
        c.peerNick = e.peerNick;
        c.size = e.size;
        c.processedSize = e.processedSize;
        c.speed = speed;
        c.timeRemaining = speed > 0 ? ((e.size - e.processedSize)) / speed : 0;
        c.status = e.status;
        c.error = e.error;
        c.icon = e.icon;
        c.progressBar = e.progressBar;
    }
    else {
        if (row < 0 || _receivers.count <= row) return;

        DCCReceiver* e = [_receivers objectAtIndex:row];
        double speed = e.speed;

        c.sendingItem = NO;
        c.stringValue = (e.status == DCC_COMPLETE) ? [e.downloadFileName lastPathComponent] : e.fileName;
        c.peerNick = e.peerNick;
        c.size = e.size;
        c.processedSize = e.processedSize;
        c.speed = speed;
        c.timeRemaining = speed > 0 ? ((e.size - e.processedSize)) / speed : 0;
        c.status = e.status;
        c.error = e.error;
        c.icon = e.icon;
        c.progressBar = e.progressBar;
    }
}

#pragma mark - Timer Delegate

- (void)updateTimer
{
    if (_timer.isActive) {
        BOOL foundActive = NO;

        for (DCCReceiver* e in _receivers) {
            if (e.status == DCC_RECEIVING) {
                foundActive = YES;
                break;
            }
        }

        if (!foundActive) {
            for (DCCSender* e in _senders) {
                if (e.status == DCC_SENDING) {
                    foundActive = YES;
                    break;
                }
            }
        }

        if (!foundActive) {
            [_timer stop];
        }
    }
    else {
        BOOL foundActive = NO;

        for (DCCReceiver* e in _receivers) {
            if (e.status == DCC_RECEIVING) {
                foundActive = YES;
                break;
            }
        }

        if (!foundActive) {
            for (DCCSender* e in _senders) {
                if (e.status == DCC_SENDING) {
                    foundActive = YES;
                    break;
                }
            }
        }

        if (foundActive) {
            [_timer start:TIMER_INTERVAL];
        }
    }
}

- (void)timerOnTimer:(Timer*)sender
{
    [self reloadReceiverTable];
    [self reloadSenderTable];
    [self updateTimer];

    for (DCCReceiver* e in _receivers) {
        [e onTimer];
    }

    for (DCCSender* e in _senders) {
        [e onTimer];
    }
}

#pragma mark - DialogWindow Delegate

- (void)dialogWindowEscape
{
    [self.window close];
}

#pragma mark - NSWindow Delegate

- (void)windowDidBecomeMain:(NSNotification *)note
{
    [self reloadReceiverTable];
    [self reloadSenderTable];
}

- (void)windowDidResignMain:(NSNotification *)note
{
    [self reloadReceiverTable];
    [self reloadSenderTable];
}

- (void)windowWillClose:(NSNotification*)note
{
    [self saveWindowState];
}

@end
