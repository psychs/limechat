#import <RubyCocoa/RBRuntime.h>

int main(int argc, const char* argv[])
{
  //setenv("RUBYCOCOA_THREAD_HOOK_DISABLE", "1", 1);
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  setenv("HOME", [[@"~/" stringByExpandingTildeInPath] UTF8String], 0);
  [pool release];
  return RBApplicationMain("rb_main.rb", argc, argv);
}
