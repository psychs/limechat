#import <RubyCocoa/RBRuntime.h>

int main(int argc, const char* argv[])
{
  setenv("RUBYCOCOA_THREAD_HOOK_DISABLE", "1", 1);
  return RBApplicationMain("rb_main.rb", argc, argv);
}
