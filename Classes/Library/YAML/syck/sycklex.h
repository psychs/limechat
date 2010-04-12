#if GRAM_FILES_HAVE_TAB_SUFFIX
#include "gram.tab.h"
#else
#include "gram.h"
#endif

int sycklex( YYSTYPE *sycklval, SyckParser *parser );
