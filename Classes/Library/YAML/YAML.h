#import <Foundation/Foundation.h>

#import "YAMLCategories.h"

id yaml_parse(NSString *str);
id yaml_parse_raw_utf8(const char *str, long len);

@interface NSObject (PublicYAMLAdditions)
// -toYAML and +fromYAML are the methods you will need to override for your classes
// overide -toYAML to return a NSArray, NSDictionary, NSString or NSNumber
- (id)toYAML;
// overide +fromYAML to read the same back in
// [MyClass fromYAML:[me toYAML]] should give a copy of me 
+ (id)fromYAML:(id)data;

// -yamlData is a sibling of -toYAML
// it wraps up the -toYAML data in a wrapper that also contains the Class
- (id)yamlData;
// -yamlParse is the opposite of -yamlData
// it will decode the wrapped up data of -yamlData
// [[me yamlData] yamlParse] should give a copy of me 
- (id)yamlParse;

// yamlDescription provides the actual yaml text that you can write out to a file
- (NSString*)yamlDescription;
@end