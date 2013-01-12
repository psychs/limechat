//
//  IRCExecCommand.m
//  LimeChat
//
//  Created by Tarcísio Gruppi on 11/01/13.
//
//

#import "IRCExecCommand.h"

@interface IRCExecCommand ()

- (void)prepareArgs;
- (void)runTask;
- (void)onTimeout:(NSNotification*)notification;
- (void)onFinish:(NSNotification*)notification;

@end

@implementation IRCExecCommand

@synthesize task;
@synthesize stringout;
@synthesize stringerr;
@synthesize command;
@synthesize arguments;
@synthesize timedout;
@synthesize sendOutput;
@synthesize timeoutSecs;
@synthesize client;
@synthesize channel;

- (id)initWithCommandString:(NSString *)cmd andClient:(IRCClient*)cli andChannel:(IRCChannel*)cha {
    self = [super init];
    if (self) {
        timedout = NO;
        sendOutput = NO;
        timeoutSecs = 10.0;
        command = [cmd retain];
        client = cli;
        channel = cha;
        [self runTask];
    }
    return self;
}

- (void)dealloc {
    [arguments release];
    [task release];
    [pipeout release];
    [pipeerr release];
    [stringout release];
    [stringerr release];
    [command release];
    [super dealloc];
}

- (void)prepareArgs {
    arguments = [[[self command] componentsSeparatedByString:@" "] mutableCopy];
    NSString *bin;
    while (YES) {
        bin = [arguments objectAtIndex:0];
        if ([bin isEqualToString:@"-o"]) {
            sendOutput = YES;
            [arguments removeObjectAtIndex:0];
        } else if ([bin isEqualToString:@"-t"]) {
            @try {
                timeoutSecs = [[arguments objectAtIndex:1] doubleValue];
                [arguments removeObjectsInRange:NSMakeRange(0, 2)];
            }
            @catch (NSError *exception) {
                [arguments removeObjectAtIndex:0];
            }
        } else {
            break;
        }
    }

    if (![bin isAbsolutePath] || ![[bin lastPathComponent] isEqualToString:@"env"]) {
        [arguments insertObject:@"/usr/bin/env" atIndex:0];
    }
}

- (void)runTask {
    [self prepareArgs];
    
    pipeout = [[NSPipe alloc] init];
    pipeerr = [[NSPipe alloc] init];

    task = [[NSTask alloc] init];
    [task setLaunchPath:[arguments objectAtIndex:0]];
    [task setArguments:[arguments subarrayWithRange:NSMakeRange(1, [arguments count] -1 )]];
    [task setStandardOutput:pipeout];
    [task setStandardError:pipeerr];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [self performSelector:@selector(onTimeout:) withObject:nil afterDelay:timeoutSecs];
    [nc addObserver:self selector:@selector(onFinish:) name:NSTaskDidTerminateNotification object:task];
    
    [task launch];
}

- (void)onTimeout:(NSNotification *)notification {
    if (task && [task isRunning]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        timedout = YES;
        [task interrupt];
        [task terminate];
        [client execCommandResult:self];
    }
}

- (void)onFinish:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSFileHandle *read;
    NSData *data;

    read = [pipeout fileHandleForReading];
    data = [read readDataToEndOfFile];
    stringout = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    read = [pipeerr fileHandleForReading];
    data = [read readDataToEndOfFile];
    stringerr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [client execCommandResult:self];
}

@end
