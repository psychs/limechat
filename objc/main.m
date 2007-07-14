#import <RubyCocoa/RBRuntime.h>

/*
void print_encodings()
{
  const NSStringEncoding *encodings = [NSString availableStringEncodings];
  NSMutableString *str = [[NSMutableString alloc] init];
  NSStringEncoding encoding;
  while ((encoding = *encodings++) != 0) {
      [str appendFormat: @"\n%d, %@, %@",
          encoding,
          [NSString localizedNameOfStringEncoding:encoding],
          CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding))
      ];
  }
  NSLog(@"%@", str);
}
*/

int main(int argc, const char* argv[])
{
  return RBApplicationMain("rb_main.rb", argc, argv);
}
