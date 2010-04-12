/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.3"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* Substitute the variable and function names.  */
#define yyparse syckparse
#define yylex   sycklex
#define yyerror syckerror
#define yylval  sycklval
#define yychar  syckchar
#define yydebug syckdebug
#define yynerrs sycknerrs


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     YAML_ANCHOR = 258,
     YAML_ALIAS = 259,
     YAML_TRANSFER = 260,
     YAML_TAGURI = 261,
     YAML_ITRANSFER = 262,
     YAML_WORD = 263,
     YAML_PLAIN = 264,
     YAML_BLOCK = 265,
     YAML_DOCSEP = 266,
     YAML_IOPEN = 267,
     YAML_INDENT = 268,
     YAML_IEND = 269
   };
#endif
/* Tokens.  */
#define YAML_ANCHOR 258
#define YAML_ALIAS 259
#define YAML_TRANSFER 260
#define YAML_TAGURI 261
#define YAML_ITRANSFER 262
#define YAML_WORD 263
#define YAML_PLAIN 264
#define YAML_BLOCK 265
#define YAML_DOCSEP 266
#define YAML_IOPEN 267
#define YAML_INDENT 268
#define YAML_IEND 269




/* Copy the first part of user declarations.  */
#line 14 "gram.y"


#define YYDEBUG 1
#define YYERROR_VERBOSE 1
#ifndef YYSTACK_USE_ALLOCA
#define YYSTACK_USE_ALLOCA 0
#endif

#include "syck.h"
#include "sycklex.h"

void apply_seq_in_map( SyckParser *parser, SyckNode *n );

#define YYPARSE_PARAM   parser
#define YYLEX_PARAM     parser

#define NULL_NODE(parser, node) \
        SyckNode *node = syck_new_str( "", scalar_plain ); \
        if ( ((SyckParser *)parser)->taguri_expansion == 1 ) \
        { \
            node->type_id = syck_taguri( YAML_DOMAIN, "null", 4 ); \
        } \
        else \
        { \
            node->type_id = syck_strndup( "null", 4 ); \
        }


/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif

#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 42 "gram.y"
{
    SYMID nodeId;
    SyckNode *nodeData;
    char *name;
}
/* Line 193 of yacc.c.  */
#line 166 "gram.c"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */
#line 179 "gram.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int i)
#else
static int
YYID (i)
    int i;
#endif
{
  return i;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  52
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   396

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  23
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  29
/* YYNRULES -- Number of rules.  */
#define YYNRULES  79
/* YYNRULES -- Number of states.  */
#define YYNSTATES  128

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   269

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,    21,    15,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,    16,     2,
       2,     2,     2,    22,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    17,     2,    18,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    19,     2,    20,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint8 yyprhs[] =
{
       0,     0,     3,     5,     8,     9,    11,    13,    15,    18,
      21,    24,    28,    30,    32,    36,    37,    40,    43,    46,
      49,    51,    54,    56,    58,    60,    63,    66,    69,    72,
      75,    77,    79,    81,    85,    87,    89,    91,    93,    95,
      99,   103,   106,   110,   113,   117,   120,   124,   127,   129,
     133,   136,   140,   143,   145,   149,   151,   153,   157,   161,
     165,   168,   172,   175,   179,   182,   184,   188,   190,   194,
     196,   200,   204,   207,   211,   215,   218,   220,   224,   226
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] =
{
      24,     0,    -1,    25,    -1,    11,    27,    -1,    -1,    33,
      -1,    26,    -1,    34,    -1,     5,    26,    -1,     6,    26,
      -1,     3,    26,    -1,    29,    26,    32,    -1,    25,    -1,
      28,    -1,    29,    28,    30,    -1,    -1,     7,    28,    -1,
       5,    28,    -1,     6,    28,    -1,     3,    28,    -1,    12,
      -1,    29,    13,    -1,    14,    -1,    13,    -1,    14,    -1,
      31,    32,    -1,     5,    33,    -1,     6,    33,    -1,     7,
      33,    -1,     3,    33,    -1,     4,    -1,     8,    -1,     9,
      -1,    29,    33,    32,    -1,    10,    -1,    35,    -1,    39,
      -1,    42,    -1,    49,    -1,    29,    37,    30,    -1,    29,
      38,    30,    -1,    15,    27,    -1,     5,    31,    38,    -1,
       5,    37,    -1,     6,    31,    38,    -1,     6,    37,    -1,
       3,    31,    38,    -1,     3,    37,    -1,    36,    -1,    38,
      31,    36,    -1,    38,    31,    -1,    17,    40,    18,    -1,
      17,    18,    -1,    41,    -1,    40,    21,    41,    -1,    25,
      -1,    48,    -1,    29,    43,    30,    -1,    29,    47,    30,
      -1,     5,    31,    47,    -1,     5,    43,    -1,     6,    31,
      47,    -1,     6,    43,    -1,     3,    31,    47,    -1,     3,
      43,    -1,    33,    -1,    22,    25,    31,    -1,    27,    -1,
      44,    16,    45,    -1,    46,    -1,    47,    31,    36,    -1,
      47,    31,    46,    -1,    47,    31,    -1,    25,    16,    27,
      -1,    19,    50,    20,    -1,    19,    20,    -1,    51,    -1,
      50,    21,    51,    -1,    25,    -1,    48,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,    63,    63,    67,    72,    77,    78,    81,    82,    87,
      92,   101,   107,   108,   111,   116,   120,   128,   133,   138,
     152,   153,   156,   159,   162,   163,   171,   176,   181,   189,
     193,   201,   214,   215,   225,   226,   227,   228,   229,   235,
     239,   245,   251,   256,   261,   266,   271,   275,   281,   285,
     290,   299,   303,   309,   313,   320,   321,   327,   332,   339,
     344,   349,   354,   359,   363,   369,   370,   376,   386,   403,
     404,   416,   424,   433,   441,   445,   451,   452,   461,   468
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "YAML_ANCHOR", "YAML_ALIAS",
  "YAML_TRANSFER", "YAML_TAGURI", "YAML_ITRANSFER", "YAML_WORD",
  "YAML_PLAIN", "YAML_BLOCK", "YAML_DOCSEP", "YAML_IOPEN", "YAML_INDENT",
  "YAML_IEND", "'-'", "':'", "'['", "']'", "'{'", "'}'", "','", "'?'",
  "$accept", "doc", "atom", "ind_rep", "atom_or_empty", "empty",
  "indent_open", "indent_end", "indent_sep", "indent_flex_end", "word_rep",
  "struct_rep", "implicit_seq", "basic_seq", "top_imp_seq",
  "in_implicit_seq", "inline_seq", "in_inline_seq", "inline_seq_atom",
  "implicit_map", "top_imp_map", "complex_key", "complex_value",
  "complex_mapping", "in_implicit_map", "basic_mapping", "inline_map",
  "in_inline_map", "inline_map_atom", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,    45,    58,    91,    93,   123,
     125,    44,    63
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    23,    24,    24,    24,    25,    25,    26,    26,    26,
      26,    26,    27,    27,    28,    28,    28,    28,    28,    28,
      29,    29,    30,    31,    32,    32,    33,    33,    33,    33,
      33,    33,    33,    33,    34,    34,    34,    34,    34,    35,
      35,    36,    37,    37,    37,    37,    37,    37,    38,    38,
      38,    39,    39,    40,    40,    41,    41,    42,    42,    43,
      43,    43,    43,    43,    43,    44,    44,    45,    46,    47,
      47,    47,    47,    48,    49,    49,    50,    50,    51,    51
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     1,     2,     0,     1,     1,     1,     2,     2,
       2,     3,     1,     1,     3,     0,     2,     2,     2,     2,
       1,     2,     1,     1,     1,     2,     2,     2,     2,     2,
       1,     1,     1,     3,     1,     1,     1,     1,     1,     3,
       3,     2,     3,     2,     3,     2,     3,     2,     1,     3,
       2,     3,     2,     1,     3,     1,     1,     3,     3,     3,
       2,     3,     2,     3,     2,     1,     3,     1,     3,     1,
       3,     3,     2,     3,     3,     2,     1,     3,     1,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       4,     0,    30,     0,     0,     0,    31,    32,    34,    15,
      20,     0,     0,     0,     2,     6,     0,     5,     7,    35,
      36,    37,    38,    10,    29,     8,    26,     9,    27,     0,
       0,     0,     0,    28,    15,    15,    15,    15,    12,     3,
      13,    15,    52,    55,     0,    53,    56,    75,    78,    79,
       0,    76,     1,     0,     0,     0,    21,    15,     0,     0,
      65,    48,     0,     0,     0,     0,    69,     0,     0,    19,
      17,    18,    15,    15,    15,    16,    15,    15,    15,    15,
       0,    15,    51,     0,    74,     0,    23,     0,    47,    64,
       0,    43,    60,     0,    45,    62,    41,     0,    24,     0,
      11,    33,    22,    39,    40,    50,    57,    15,    58,    72,
      14,    73,    54,    77,    65,    46,    63,    42,    59,    44,
      61,    66,    25,    49,    67,    68,    70,    71
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,    13,    38,    15,    39,    40,    16,   103,    99,   101,
      17,    18,    19,    61,    62,    63,    20,    44,    45,    21,
      64,    65,   125,    66,    67,    46,    22,    50,    51
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -97
static const yytype_int16 yypact[] =
{
     250,   318,   -97,   318,   318,   374,   -97,   -97,   -97,   335,
     -97,   267,   232,     7,   -97,   -97,   192,   -97,   -97,   -97,
     -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   374,
     374,   374,   352,   -97,   335,   335,   335,   384,   -97,   -97,
     -97,   212,   -97,    10,     0,   -97,   -97,   -97,    10,   -97,
      -4,   -97,   -97,   284,   284,   284,   -97,   335,   318,    30,
      30,   -97,    -2,    36,    -2,    16,   -97,    36,    30,   -97,
     -97,   -97,   384,   384,   384,   -97,   363,   301,   301,   301,
      -2,   335,   -97,   318,   -97,   318,   -97,   158,   -97,   -97,
     158,   -97,   -97,   158,   -97,   -97,   -97,    24,   -97,    30,
     -97,   -97,   -97,   -97,   -97,    26,   -97,   335,   -97,   158,
     -97,   -97,   -97,   -97,   -97,    24,    24,    24,    24,    24,
      24,   -97,   -97,   -97,   -97,   -97,   -97,   -97
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -97,   -97,     8,    81,   -56,   109,    33,   -53,    74,   -54,
      -1,   -97,   -97,   -96,   -31,   -32,   -97,   -97,   -44,   -97,
      77,   -97,   -97,   -52,     9,    -6,   -97,   -97,   -29
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -1
static const yytype_uint8 yytable[] =
{
      24,    96,    26,    28,    33,   100,    49,    52,    14,   123,
     104,   106,   102,   126,   108,    60,    84,    85,    82,    43,
      48,    83,    88,    91,    94,   111,    81,   110,    24,    26,
      28,    68,   107,    24,    26,    28,    33,    86,    32,   112,
      60,    57,    41,    86,    98,   122,    88,    91,    94,    86,
     102,   124,    24,    26,    28,   115,   113,   127,   117,     0,
       0,   119,    32,    32,    32,    32,    97,    41,    41,    41,
      76,    24,    26,    28,    41,    68,    24,    26,    28,    49,
       0,     0,    23,     0,    25,    27,   114,     0,     0,   114,
      41,    43,   114,    48,     0,     0,   116,    59,     0,   118,
       0,     0,   120,     0,     0,    76,    76,    76,   114,    76,
      41,    41,    41,     0,    41,    23,    25,    27,     0,     0,
      32,     0,    59,    32,     0,     0,    32,    87,    90,    93,
      89,    92,    95,     0,    23,    25,    27,   105,     0,     0,
      41,   109,    32,    69,    70,    71,    75,     0,     0,     0,
      80,    87,    90,    93,    89,    92,    95,     0,    23,    25,
      27,    29,     2,    30,    31,     5,     6,     7,     0,     0,
      10,   121,     0,    57,     0,     0,     0,     0,     0,     0,
      58,    69,    70,    71,     0,    80,    69,    70,    71,   105,
     109,   105,   109,   105,   109,    53,     2,    54,    55,     5,
       6,     7,     8,     0,    10,    56,     0,    57,     0,    11,
       0,    12,     0,     0,    58,    77,     2,    78,    79,    37,
       6,     7,     8,     0,    10,    56,     0,    57,     0,    11,
       0,    12,     0,     0,    58,     1,     2,     3,     4,     5,
       6,     7,     8,     0,    10,     0,     0,     0,     0,    11,
       0,    12,    47,     1,     2,     3,     4,     5,     6,     7,
       8,     9,    10,     0,     0,     0,     0,    11,     0,    12,
       1,     2,     3,     4,     5,     6,     7,     8,     0,    10,
       0,     0,     0,     0,    11,    42,    12,    53,     2,    54,
      55,     5,     6,     7,     8,     0,    10,    86,     0,     0,
       0,    11,     0,    12,    77,     2,    78,    79,    37,     6,
       7,     8,     0,    10,    86,     0,     0,     0,    11,     0,
      12,     1,     2,     3,     4,     5,     6,     7,     8,     0,
      10,     0,     0,     0,     0,    11,     0,    12,    34,     2,
      35,    36,    37,     6,     7,     8,     0,    10,     0,     0,
       0,     0,    11,     0,    12,    29,     2,    30,    31,     5,
       6,     7,     0,     0,    10,    56,    72,     2,    73,    74,
      37,     6,     7,     0,     0,    10,    56,    29,     2,    30,
      31,     5,     6,     7,     0,     0,    10,    72,     2,    73,
      74,    37,     6,     7,     0,     0,    10
};

static const yytype_int8 yycheck[] =
{
       1,    57,     3,     4,     5,    59,    12,     0,     0,   105,
      63,    64,    14,   109,    67,    16,    20,    21,    18,    11,
      12,    21,    53,    54,    55,    81,    16,    80,    29,    30,
      31,    32,    16,    34,    35,    36,    37,    13,     5,    83,
      41,    15,     9,    13,    14,    99,    77,    78,    79,    13,
      14,   107,    53,    54,    55,    87,    85,   109,    90,    -1,
      -1,    93,    29,    30,    31,    32,    58,    34,    35,    36,
      37,    72,    73,    74,    41,    76,    77,    78,    79,    85,
      -1,    -1,     1,    -1,     3,     4,    87,    -1,    -1,    90,
      57,    83,    93,    85,    -1,    -1,    87,    16,    -1,    90,
      -1,    -1,    93,    -1,    -1,    72,    73,    74,   109,    76,
      77,    78,    79,    -1,    81,    34,    35,    36,    -1,    -1,
      87,    -1,    41,    90,    -1,    -1,    93,    53,    54,    55,
      53,    54,    55,    -1,    53,    54,    55,    63,    -1,    -1,
     107,    67,   109,    34,    35,    36,    37,    -1,    -1,    -1,
      41,    77,    78,    79,    77,    78,    79,    -1,    77,    78,
      79,     3,     4,     5,     6,     7,     8,     9,    -1,    -1,
      12,    97,    -1,    15,    -1,    -1,    -1,    -1,    -1,    -1,
      22,    72,    73,    74,    -1,    76,    77,    78,    79,   115,
     116,   117,   118,   119,   120,     3,     4,     5,     6,     7,
       8,     9,    10,    -1,    12,    13,    -1,    15,    -1,    17,
      -1,    19,    -1,    -1,    22,     3,     4,     5,     6,     7,
       8,     9,    10,    -1,    12,    13,    -1,    15,    -1,    17,
      -1,    19,    -1,    -1,    22,     3,     4,     5,     6,     7,
       8,     9,    10,    -1,    12,    -1,    -1,    -1,    -1,    17,
      -1,    19,    20,     3,     4,     5,     6,     7,     8,     9,
      10,    11,    12,    -1,    -1,    -1,    -1,    17,    -1,    19,
       3,     4,     5,     6,     7,     8,     9,    10,    -1,    12,
      -1,    -1,    -1,    -1,    17,    18,    19,     3,     4,     5,
       6,     7,     8,     9,    10,    -1,    12,    13,    -1,    -1,
      -1,    17,    -1,    19,     3,     4,     5,     6,     7,     8,
       9,    10,    -1,    12,    13,    -1,    -1,    -1,    17,    -1,
      19,     3,     4,     5,     6,     7,     8,     9,    10,    -1,
      12,    -1,    -1,    -1,    -1,    17,    -1,    19,     3,     4,
       5,     6,     7,     8,     9,    10,    -1,    12,    -1,    -1,
      -1,    -1,    17,    -1,    19,     3,     4,     5,     6,     7,
       8,     9,    -1,    -1,    12,    13,     3,     4,     5,     6,
       7,     8,     9,    -1,    -1,    12,    13,     3,     4,     5,
       6,     7,     8,     9,    -1,    -1,    12,     3,     4,     5,
       6,     7,     8,     9,    -1,    -1,    12
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     3,     4,     5,     6,     7,     8,     9,    10,    11,
      12,    17,    19,    24,    25,    26,    29,    33,    34,    35,
      39,    42,    49,    26,    33,    26,    33,    26,    33,     3,
       5,     6,    29,    33,     3,     5,     6,     7,    25,    27,
      28,    29,    18,    25,    40,    41,    48,    20,    25,    48,
      50,    51,     0,     3,     5,     6,    13,    15,    22,    26,
      33,    36,    37,    38,    43,    44,    46,    47,    33,    28,
      28,    28,     3,     5,     6,    28,    29,     3,     5,     6,
      28,    16,    18,    21,    20,    21,    13,    31,    37,    43,
      31,    37,    43,    31,    37,    43,    27,    25,    14,    31,
      32,    32,    14,    30,    30,    31,    30,    16,    30,    31,
      30,    27,    41,    51,    33,    38,    47,    38,    47,    38,
      47,    31,    32,    36,    27,    45,    36,    46
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *bottom, yytype_int16 *top)
#else
static void
yy_stack_print (bottom, top)
    yytype_int16 *bottom;
    yytype_int16 *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yyrule)
    YYSTYPE *yyvsp;
    int yyrule;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      fprintf (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       );
      fprintf (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  YYUSE (yyvaluep);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
	break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */






/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
  /* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;

  int yystate;
  int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Look-ahead token as an internal (translated) token number.  */
  int yytoken = 0;
#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  yytype_int16 yyssa[YYINITDEPTH];
  yytype_int16 *yyss = yyssa;
  yytype_int16 *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  YYSTYPE *yyvsp;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     look-ahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to look-ahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a look-ahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid look-ahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the look-ahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:
#line 64 "gram.y"
    {
           ((SyckParser *)parser)->root = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(1) - (1)].nodeData) );
        }
    break;

  case 3:
#line 68 "gram.y"
    {
           ((SyckParser *)parser)->root = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(2) - (2)].nodeData) );
        }
    break;

  case 4:
#line 72 "gram.y"
    {
           ((SyckParser *)parser)->eof = 1;
        }
    break;

  case 8:
#line 83 "gram.y"
    { 
            syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
            (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
        }
    break;

  case 9:
#line 88 "gram.y"
    {
            syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), 0 );
            (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
        }
    break;

  case 10:
#line 93 "gram.y"
    { 
           /*
            * _Anchors_: The language binding must keep a separate symbol table
            * for anchors.  The actual ID in the symbol table is returned to the
            * higher nodes, though.
            */
           (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData) );
        }
    break;

  case 11:
#line 102 "gram.y"
    {
           (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
        }
    break;

  case 14:
#line 112 "gram.y"
    {
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 15:
#line 116 "gram.y"
    {
                    NULL_NODE( parser, n );
                    (yyval.nodeData) = n;
                }
    break;

  case 16:
#line 121 "gram.y"
    { 
                   if ( ((SyckParser *)parser)->implicit_typing == 1 )
                   {
                      try_tag_implicit( (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                   }
                   (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 17:
#line 129 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 18:
#line 134 "gram.y"
    {
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 19:
#line 139 "gram.y"
    { 
                   /*
                    * _Anchors_: The language binding must keep a separate symbol table
                    * for anchors.  The actual ID in the symbol table is returned to the
                    * higher nodes, though.
                    */
                   (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData) );
                }
    break;

  case 26:
#line 172 "gram.y"
    { 
               syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
               (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
            }
    break;

  case 27:
#line 177 "gram.y"
    { 
               syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), 0 );
               (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
            }
    break;

  case 28:
#line 182 "gram.y"
    { 
               if ( ((SyckParser *)parser)->implicit_typing == 1 )
               {
                  try_tag_implicit( (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
               }
               (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
            }
    break;

  case 29:
#line 190 "gram.y"
    { 
               (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData) );
            }
    break;

  case 30:
#line 194 "gram.y"
    {
               /*
                * _Aliases_: The anchor symbol table is scanned for the anchor name.
                * The anchor's ID in the language's symbol table is returned.
                */
               (yyval.nodeData) = syck_hdlr_get_anchor( (SyckParser *)parser, (yyvsp[(1) - (1)].name) );
            }
    break;

  case 31:
#line 202 "gram.y"
    { 
               SyckNode *n = (yyvsp[(1) - (1)].nodeData);
               if ( ((SyckParser *)parser)->taguri_expansion == 1 )
               {
                   n->type_id = syck_taguri( YAML_DOMAIN, "str", 3 );
               }
               else
               {
                   n->type_id = syck_strndup( "str", 3 );
               }
               (yyval.nodeData) = n;
            }
    break;

  case 33:
#line 216 "gram.y"
    {
               (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
            }
    break;

  case 39:
#line 236 "gram.y"
    { 
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 40:
#line 240 "gram.y"
    { 
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 41:
#line 246 "gram.y"
    { 
                    (yyval.nodeId) = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(2) - (2)].nodeData) );
                }
    break;

  case 42:
#line 252 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[(3) - (3)].nodeData);
                }
    break;

  case 43:
#line 257 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 44:
#line 262 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[(3) - (3)].nodeData);
                }
    break;

  case 45:
#line 267 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 46:
#line 272 "gram.y"
    { 
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData) );
                }
    break;

  case 47:
#line 276 "gram.y"
    { 
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData) );
                }
    break;

  case 48:
#line 282 "gram.y"
    {
                    (yyval.nodeData) = syck_new_seq( (yyvsp[(1) - (1)].nodeId) );
                }
    break;

  case 49:
#line 286 "gram.y"
    { 
                    syck_seq_add( (yyvsp[(1) - (3)].nodeData), (yyvsp[(3) - (3)].nodeId) );
                    (yyval.nodeData) = (yyvsp[(1) - (3)].nodeData);
				}
    break;

  case 50:
#line 291 "gram.y"
    { 
                    (yyval.nodeData) = (yyvsp[(1) - (2)].nodeData);
				}
    break;

  case 51:
#line 300 "gram.y"
    { 
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 52:
#line 304 "gram.y"
    { 
                    (yyval.nodeData) = syck_alloc_seq();
                }
    break;

  case 53:
#line 310 "gram.y"
    {
                    (yyval.nodeData) = syck_new_seq( syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(1) - (1)].nodeData) ) );
                }
    break;

  case 54:
#line 314 "gram.y"
    { 
                    syck_seq_add( (yyvsp[(1) - (3)].nodeData), syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(3) - (3)].nodeData) ) );
                    (yyval.nodeData) = (yyvsp[(1) - (3)].nodeData);
				}
    break;

  case 57:
#line 328 "gram.y"
    { 
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[(2) - (3)].nodeData) );
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 58:
#line 333 "gram.y"
    { 
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[(2) - (3)].nodeData) );
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 59:
#line 340 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[(3) - (3)].nodeData);
                }
    break;

  case 60:
#line 345 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 61:
#line 350 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[(3) - (3)].nodeData);
                }
    break;

  case 62:
#line 355 "gram.y"
    { 
                    syck_add_transfer( (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[(2) - (2)].nodeData);
                }
    break;

  case 63:
#line 360 "gram.y"
    { 
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (3)].name), (yyvsp[(3) - (3)].nodeData) );
                }
    break;

  case 64:
#line 364 "gram.y"
    { 
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[(1) - (2)].name), (yyvsp[(2) - (2)].nodeData) );
                }
    break;

  case 66:
#line 371 "gram.y"
    {
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 68:
#line 387 "gram.y"
    {
                    (yyval.nodeData) = syck_new_map( 
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(1) - (3)].nodeData) ), 
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(3) - (3)].nodeData) ) );
                }
    break;

  case 70:
#line 405 "gram.y"
    {
                    if ( (yyvsp[(1) - (3)].nodeData)->shortcut == NULL )
                    {
                        (yyvsp[(1) - (3)].nodeData)->shortcut = syck_new_seq( (yyvsp[(3) - (3)].nodeId) );
                    }
                    else
                    {
                        syck_seq_add( (yyvsp[(1) - (3)].nodeData)->shortcut, (yyvsp[(3) - (3)].nodeId) );
                    }
                    (yyval.nodeData) = (yyvsp[(1) - (3)].nodeData);
                }
    break;

  case 71:
#line 417 "gram.y"
    {
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[(1) - (3)].nodeData) );
                    syck_map_update( (yyvsp[(1) - (3)].nodeData), (yyvsp[(3) - (3)].nodeData) );
                    syck_free_node( (yyvsp[(3) - (3)].nodeData) );
                    (yyvsp[(3) - (3)].nodeData) = NULL;
                    (yyval.nodeData) = (yyvsp[(1) - (3)].nodeData);
                }
    break;

  case 72:
#line 425 "gram.y"
    {
                    (yyval.nodeData) = (yyvsp[(1) - (2)].nodeData);
                }
    break;

  case 73:
#line 434 "gram.y"
    {
                    (yyval.nodeData) = syck_new_map( 
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(1) - (3)].nodeData) ), 
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(3) - (3)].nodeData) ) );
                }
    break;

  case 74:
#line 442 "gram.y"
    {
                    (yyval.nodeData) = (yyvsp[(2) - (3)].nodeData);
                }
    break;

  case 75:
#line 446 "gram.y"
    {
                    (yyval.nodeData) = syck_alloc_map();
                }
    break;

  case 77:
#line 453 "gram.y"
    {
                    syck_map_update( (yyvsp[(1) - (3)].nodeData), (yyvsp[(3) - (3)].nodeData) );
                    syck_free_node( (yyvsp[(3) - (3)].nodeData) );
                    (yyvsp[(3) - (3)].nodeData) = NULL;
                    (yyval.nodeData) = (yyvsp[(1) - (3)].nodeData);
				}
    break;

  case 78:
#line 462 "gram.y"
    {
                    NULL_NODE( parser, n );
                    (yyval.nodeData) = syck_new_map( 
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[(1) - (1)].nodeData) ), 
                        syck_hdlr_add_node( (SyckParser *)parser, n ) );
                }
    break;


/* Line 1267 of yacc.c.  */
#line 1988 "gram.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (yymsg);
	  }
	else
	  {
	    yyerror (YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse look-ahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse look-ahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#ifndef yyoverflow
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEOF && yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}


#line 471 "gram.y"


void
apply_seq_in_map( SyckParser *parser, SyckNode *n )
{
    long map_len;
    if ( n->shortcut == NULL )
    {
        return;
    }

    map_len = syck_map_count( n );
    syck_map_assign( n, map_value, map_len - 1,
        syck_hdlr_add_node( parser, n->shortcut ) );

    n->shortcut = NULL;
}


