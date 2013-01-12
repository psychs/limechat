//
//  IRCExecCommand.h
//  LimeChat
//
//  Created by Tarcísio Gruppi on 11/01/13.
//
//

#import <Foundation/Foundation.h>

@interface IRCExecCommand : NSObject {
    __strong NSTask *task;
    __strong NSString *stringout;
    __strong NSString *stringerr;
    __weak NSString *command;
    BOOL timedout;
    BOOL sendOutput;
    
    @private
    __strong NSMutableArray *arguments;
    __strong NSPipe *pipeout;
    __strong NSPipe *pipeerr;
}

@property (nonatomic, readonly, strong) NSTask *task;
@property (nonatomic, readonly, strong) NSString *stringout;
@property (nonatomic, readonly, strong) NSString *stringerr;
@property (nonatomic, readonly, weak) NSString *command;
@property (nonatomic, readonly) BOOL timedout;
@property (nonatomic, readonly) BOOL sendOutput;

- (id)initWithCommandString:(NSString*)command;

@end
