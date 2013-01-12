//
//  IRCExecCommand.h
//  LimeChat
//
//  Created by Tarcísio Gruppi on 11/01/13.
//
//

#import <Foundation/Foundation.h>
#import "../IRCClient.h"

@interface IRCExecCommand : NSObject {
    __strong NSTask *task;
    __strong NSString *stringout;
    __strong NSString *stringerr;
    __strong NSString *command;
    __strong NSMutableArray *arguments;
    __strong NSPipe *pipeout;
    __strong NSPipe *pipeerr;

    __weak IRCClient *client;
    __weak IRCChannel *channel;

    BOOL timedout;
    BOOL sendOutput;

    double timeoutSecs;
}

@property (nonatomic, readonly, strong) NSMutableArray *arguments;
@property (nonatomic, readonly, strong) NSTask *task;
@property (nonatomic, readonly, strong) NSString *stringout;
@property (nonatomic, readonly, strong) NSString *stringerr;
@property (nonatomic, readonly, strong) NSString *command;
@property (nonatomic, readonly, weak) IRCClient *client;
@property (nonatomic, readonly, weak) IRCChannel *channel;
@property (nonatomic, readonly) double timeoutSecs;
@property (nonatomic, readonly) BOOL timedout;
@property (nonatomic, readonly) BOOL sendOutput;

- (id)initWithCommandString:(NSString*)command andClient:(IRCClient*)client andChannel:(IRCChannel*)channel;

@end
