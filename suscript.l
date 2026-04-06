%{
#include "suscript.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
%}

%option yylineno
%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT_NUM     {DIGIT}+
FLOAT_NUM   {DIGIT}+"."{DIGIT}+
CHAR_LIT    '[^']'
STR_LIT     \"[^"\n]*\"

%%

[ \t\r\n]+          { /* ignore whitespaces */ }

"//".*              { /* ignore single-line comment */ }

"/*"                {
                        int c;
                        while ((c = input()) != EOF) {
                            if (c == '*') {
                                int next = input();
                                if (next == '/') break;
                                unput(next);
                            }
                        }
                    }

"purno"             { return INT; }
"doshomik"          { return FLOAT; }
"okkhor"            { return CHAR; }
"tainaki"           { return BOOL; }
"dhoreNao"          { return CONST; }

"asolkaj"           { return MAIN; }
"kaj"               { return FUNC; }
"ferot"             { return RETURN; }

"jodi"              { return IF; }
"nahole jodi"       { return ELSEIF; }
"nahole"            { return ELSE; }

"shuru"             { return FOR; }
"jotokkhon"         { return WHILE; }
"koro"              { return DO; }
"thamo"             { return BREAK; }
"porer_bar"         { return CONTINUE; }

"lekhoLine"         { return PRINTLN; }
"lekho"             { return PRINT; }
"poro"              { return SCAN; }

"shotto"            { yylval.str = strdup("1"); return TRUE_LIT; }
"mittha"            { yylval.str = strdup("0"); return FALSE_LIT; }

{FLOAT_NUM}         { yylval.str = strdup(yytext); return FLOAT_LIT; }
{INT_NUM}           { yylval.str = strdup(yytext); return INT_LIT; }

{STR_LIT}           { yylval.str = strdup(yytext); return STRING_LIT; }
{CHAR_LIT}          { yylval.str = strdup(yytext); return CHAR_LIT; }

{ID}                { yylval.str = strdup(yytext); return IDENTIFIER; }

"=="                { yylval.str = strdup(yytext); return RELOP; }
"!="                { yylval.str = strdup(yytext); return RELOP; }
"<="                { yylval.str = strdup(yytext); return RELOP; }
">="                { yylval.str = strdup(yytext); return RELOP; }
"<"                 { yylval.str = strdup(yytext); return RELOP; }
">"                 { yylval.str = strdup(yytext); return RELOP; }

"&&"                { return AND; }
"||"                { return OR; }
"!"                 { return NOT; }

"++"                { return INC; }
"--"                { return DEC; }
"+="                { yylval.str = strdup(yytext); return ASSIGNOP; }
"-="                { yylval.str = strdup(yytext); return ASSIGNOP; }
"*="                { yylval.str = strdup(yytext); return ASSIGNOP; }
"/="                { yylval.str = strdup(yytext); return ASSIGNOP; }

"+"                 { yylval.str = strdup(yytext); return ADDOP; }
"-"                 { yylval.str = strdup(yytext); return ADDOP; }
"*"                 { yylval.str = strdup(yytext); return MULOP; }
"/"                 { yylval.str = strdup(yytext); return MULOP; }
"%"                 { yylval.str = strdup(yytext); return MULOP; }

"="                 { return '='; }
";"                 { return ';'; }
","                 { return ','; }
"("                 { return '('; }
")"                 { return ')'; }
"{"                 { return '{'; }
"}"                 { return '}'; }
"["                 { return '['; }
"]"                 { return ']'; }

.                   {
                        fprintf(stderr, "Lexical Error at line %d: unknown character '%s'\n",
                                yylineno, yytext);
                    }

%%
