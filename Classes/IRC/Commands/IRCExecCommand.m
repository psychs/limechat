//
//  IRCExecCommand.m
//  LimeChat
//
//  Created by Tarcísio Gruppi on 11/01/13.
//
//

#import "IRCExecCommand.h"

@interface IRCExecCommand ()

@property (nonatomic, readwrite, strong) NSMutableArray *arguments;
@property (nonatomic, readwrite) NSString *command;
@property (nonatomic, readwrite) BOOL sendOutput;

- (void)prepareArgs;
- (void)runTask;

@end

@implementation IRCExecCommand

@synthesize task;
@synthesize stringout;
@synthesize stringerr;
@synthesize command;
@synthesize arguments;
@synthesize timedout;
@synthesize sendOutput;

- (id)initWithCommandString:(NSString *)command {
    self = [super init];
    if (self) {
        timedout = NO;
        sendOutput = NO;
        [self setCommand:command];
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
    [super dealloc];
}

- (void)prepareArgs {
    arguments = [[[self command] componentsSeparatedByString:@" "] mutableCopy];
    NSString *bin = [arguments objectAtIndex:0];
    if ([bin isEqualToString:@"-o"]) {
        sendOutput = YES;
        [arguments removeObjectAtIndex:0];
        bin = [arguments objectAtIndex:0];
    }

    if (![bin isAbsolutePath] || ![[bin lastPathComponent] isEqualToString:@"env"]) {
        [arguments insertObject:@"/usr/bin/env" atIndex:0];
    }
}

- (void)runTask {
    [self prepareArgs];
    NSDate *timeout = [[NSDate date] dateByAddingTimeInterval:10];
    
    pipeout = [[NSPipe alloc] init];
    pipeerr = [[NSPipe alloc] init];

    task = [[NSTask alloc] init];
    [task setLaunchPath:[arguments objectAtIndex:0]];
    [task setArguments:[arguments subarrayWithRange:NSMakeRange(1, [arguments count] -1 )]];
    [task setStandardOutput:pipeout];
    [task setStandardError:pipeerr];
    
    [task launch];
    
    while (task != nil && [task isRunning]) {
        if ([[NSDate date] compare:(id)timeout] == NSOrderedDescending) {
            timedout = YES;
            [task terminate];
        }
    }
    
    if (!timedout) {
        NSFileHandle *read;
        NSData *data;
        
        read = [pipeout fileHandleForReading];
        data = [read readDataToEndOfFile];
        stringout = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        read = [pipeerr fileHandleForReading];
        data = [read readDataToEndOfFile];
        stringerr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

@end
