//
//  YAMLCategories.h
//  YAML
//
//  Created by William Thimbleby on Sat Sep 25 2004.
//  Copyright (c) 2004 William Thimbleby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YAMLWrapper : NSObject
{
	Class tag;
	id data;
}
+ (id)wrapperWithData:(id)d tag:(Class)cn;
- (id)initWrapperWithData:(id)d tag:(Class)cn;
- (id)data;
- (Class)tag;
@end

@interface NSString (YAMLAdditions)
+ (id)yamlStringWithUTF8String:(const char *)bytes length:(unsigned)length;
- (int)yamlIndent;
- (NSString*)yamlIndented:(int)indent;
- (NSString*)yamlDescriptionWithIndent:(int)indent;
@end

@interface NSArray (YAMLAdditions)
- (NSString*)yamlDescriptionWithIndent:(int)indent;
- (NSArray*)yamlCollectWithSelector:(SEL)aSelector withObject:(id)anObject;
- (NSArray*)yamlCollectWithSelector:(SEL)aSelector;
@end

@interface NSDictionary (YAMLAdditions)
- (NSString*)yamlDescriptionWithIndent:(int)indent;
- (NSDictionary*)yamlCollectWithSelector:(SEL)aSelector withObject:(id)anObject;
- (NSDictionary*)yamlCollectWithSelector:(SEL)aSelector;
@end

@interface NSObject (YAMLAdditions)
- (id)yamlData;
- (id)toYAML;
- (NSString*)yamlDescription;
- (NSString*)yamlDescriptionWithIndent:(int)indent;
- (void)yamlPerformSelector:(SEL)sel withEachObjectInArray:(NSArray *)array;
- (void)yamlPerformSelector:(SEL)sel withEachObjectInSet:(NSSet *)set;
@end

@interface NSData (YAMLAdditions) 
-(id) yamlDescriptionWithIndent:(int)indent;
-(id) toYAML;
@end
