#import <Cocoa/Cocoa.h>


@interface IRCSendingMessage : NSObject
{
	NSString* command;
	NSMutableArray* params;
	int penalty;
	BOOL completeColon;
	NSString* string;
}

@property (nonatomic, readonly) NSString* command;
@property (nonatomic, readonly) NSMutableArray* params;
@property (nonatomic, assign) int penalty;
@property (nonatomic, assign) BOOL completeColon;
@property (nonatomic, readonly) NSString* string;

- (id)initWithCommand:(NSString*)aCommand;
- (void)addParameter:(NSString*)parameter;

@end
