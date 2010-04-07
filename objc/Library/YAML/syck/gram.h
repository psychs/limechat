/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

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




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 42 "gram.y"
{
    SYMID nodeId;
    SyckNode *nodeData;
    char *name;
}
/* Line 1529 of yacc.c.  */
#line 83 "gram.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



