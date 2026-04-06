%{
#include "symbol_table.h"
#include "constant_fold.h"
#include "tac.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylex();
extern int yylineno;
void yyerror(const char *s);

FILE *out;               /* C output file  */
char current_type[20];   /* set by type_name rule */
int  indent_level = 0;

void print_indent() {
    for (int i = 0; i < indent_level; i++)
        fprintf(out, "    ");
}

static const char *infer_expr_type(const char *s) {
    if (!s || !*s) return "unknown";
    const char *p = s;
    if (*p == '-') p++;
    int has_dot = 0, all_num = 1;
    for (const char *q = p; *q; q++) {
        if      (*q == '.') has_dot = 1;
        else if (!isdigit((unsigned char)*q)) { all_num = 0; break; }
    }
    if (all_num && has_dot && p < s+strlen(s)) return "float";
    all_num = 1;
    for (const char *q = s; *q; q++)
        if (!isdigit((unsigned char)*q)) { all_num = 0; break; }
    if (all_num && *s) return "int";
    if (strcmp(s,"1")==0 || strcmp(s,"0")==0) return "bool";
    if (s[0]=='\'' && s[2]=='\'') return "char";
    if (symbol_exists(s)) return get_type(s);
    return "unknown";
}

static char *type_coerce(const char *expr, const char *from_t,
                         const char *to_t, int line) {
    if (strcmp(from_t, to_t)==0 || strcmp(from_t,"unknown")==0)
        return strdup(expr);
    if (strcmp(from_t,"float")==0 && strcmp(to_t,"int")==0) {
        fprintf(stderr,
            "Type Warning at line %d: implicit narrowing "
            "doshomik (float) -> purno (int), value will be truncated\n", line);
        char *buf = malloc(strlen(expr)+16);
        sprintf(buf, "(int)(%s)", expr);
        return buf;
    }
    if (strcmp(from_t,"int")==0 && strcmp(to_t,"float")==0) {
        char *buf = malloc(strlen(expr)+16);
        sprintf(buf, "(float)(%s)", expr);
        return buf;
    }
    /* bool<->int, char<->int: silent */
    return strdup(expr);
}
%}

%union { char *str; }

%token <str> INT_LIT FLOAT_LIT STRING_LIT CHAR_LIT TRUE_LIT FALSE_LIT
%token <str> IDENTIFIER RELOP ADDOP MULOP ASSIGNOP
%token INT FLOAT CHAR BOOL CONST
%token MAIN FUNC RETURN IF ELSEIF ELSE
%token FOR WHILE DO BREAK CONTINUE
%token PRINT PRINTLN SCAN
%token AND OR NOT INC DEC

%type <str> type_name param_list param_list_opt param_item
%type <str> expr call_expr arg_list arg_list_opt
%type <str> for_init for_cond for_iter

%right '='
%left  OR
%left  AND
%right NOT
%left  RELOP
%left  ADDOP
%left  MULOP
%right UMINUS

%start program

%%

program : func_list ;

func_list
    : /* empty */
    | func_list func_def
    ;

func_def
    : type_name MAIN '(' ')'
      {
          push_scope();
          tac_emit_comment("--- begin main ---");
          tac_emit_label("main");
          fprintf(out, "int main(void) ");
          free($1);
      }
      block
      { pop_scope(); }

    | type_name IDENTIFIER '(' param_list_opt ')'
      {
          push_scope();
          char comment[128];
          sprintf(comment, "--- function %s ---", $2);
          tac_emit_comment(comment);
          tac_emit_label($2);
          fprintf(out, "%s %s(%s) ", $1, $2, $4 ? $4 : "void");
          free($1); free($2); if ($4) free($4);
      }
      block
      { pop_scope(); }

    | FUNC IDENTIFIER '(' param_list_opt ')'
      {
          push_scope();
          char comment[128];
          sprintf(comment, "--- function %s ---", $2);
          tac_emit_comment(comment);
          tac_emit_label($2);
          fprintf(out, "int %s(%s) ", $2, $4 ? $4 : "void");
          free($2); if ($4) free($4);
      }
      block
      { pop_scope(); }
    ;

param_list_opt : /* empty */ { $$ = NULL; } | param_list { $$ = $1; } ;

param_list
    : param_item { $$ = $1; }
    | param_list ',' param_item
      {
          char *buf = malloc(strlen($1)+strlen($3)+4);
          sprintf(buf, "%s, %s", $1, $3);
          free($1); free($3); $$ = buf;
      }
    ;

param_item
    : type_name IDENTIFIER
      {
          add_symbol($2, $1);
          tac_emit_param($2);
          char *buf = malloc(strlen($1)+strlen($2)+2);
          sprintf(buf, "%s %s", $1, $2);
          free($1); free($2); $$ = buf;
      }
    ;

block
    : '{'
      { fprintf(out, "{\n"); indent_level++; push_scope(); }
      stmt_list
      '}'
      { indent_level--; pop_scope(); print_indent(); fprintf(out, "}\n"); }
    ;

stmt_list : /* empty */ | stmt_list stmt ;

stmt
    : decl_stmt     ';'
    | assign_stmt   ';'
    | io_stmt
    | if_stmt
    | for_loop
    | while_loop
    | do_while_loop
    | return_stmt   ';'
    | break_stmt    ';'
    | continue_stmt ';'
    | call_stmt     ';'
    | block
    ;

decl_stmt
    : CONST type_name IDENTIFIER '=' expr
      {
          const char *et = infer_expr_type($5);
          char *val = type_coerce($5, et, $2, yylineno);
          add_symbol($3, $2);
          /* TAC */
          tac_emit_assign($3, val);
          /* C */
          print_indent();
          fprintf(out, "const %s %s = %s;\n", $2, $3, val);
          free(val); free($2); free($3); free($5);
      }
    | type_name IDENTIFIER '=' expr
      {
          const char *et = infer_expr_type($4);
          char *val = type_coerce($4, et, $1, yylineno);
          add_symbol($2, $1);
          /* TAC */
          tac_emit_assign($2, val);
          /* C */
          print_indent();
          fprintf(out, "%s %s = %s;\n", $1, $2, val);
          free(val); free($1); free($2); free($4);
      }
    | type_name IDENTIFIER
      {
          add_symbol($2, $1);
          /* TAC: just note the declaration */
          char tbuf[128];
          sprintf(tbuf, "DECLARE %s %s", $1, $2);
          tac_emit_comment(tbuf);
          /* C */
          print_indent();
          fprintf(out, "%s %s;\n", $1, $2);
          free($1); free($2);
      }
    ;

assign_stmt
    : IDENTIFIER '=' expr
      {yylineno
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          const char *var_t  = get_type($1);
          const char *expr_t = infer_expr_type($3);
          char *val = type_coerce($3, expr_t, var_t, yylineno);
          /* TAC */
          tac_emit_assign($1, val);
          /* C */
          print_indent();
          fprintf(out, "%s = %s;\n", $1, val);
          free(val); free($1); free($3);
      }
    | IDENTIFIER ASSIGNOP expr
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          /* TAC: x += y  →  x = x op y */
          char op[4] = {$2[0], '\0'}; /* extract operator char: +,-,*,/ */
          const char *tmp = tac_new_temp();
          tac_emit_binop(tmp, $1, op, $3);
          tac_emit_assign($1, tmp);
          /* C */
          print_indent();
          fprintf(out, "%s %s %s;\n", $1, $2, $3);
          free($1); free($2); free($3);
      }
    | IDENTIFIER INC
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          /* TAC: x = x + 1 */
          tac_emit_binop($1, $1, "+", "1");
          print_indent(); fprintf(out, "%s++;\n", $1); free($1);
      }
    | IDENTIFIER DEC
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          /* TAC: x = x - 1 */
          tac_emit_binop($1, $1, "-", "1");
          print_indent(); fprintf(out, "%s--;\n", $1); free($1);
      }
    ;

io_stmt
    : PRINT   '(' print_list ')' ';'
    | PRINTLN '(' print_list ')' ';'
      { print_indent(); fprintf(out, "printf(\"\\n\");\n"); }
    | PRINTLN '(' ')' ';'
      { print_indent(); fprintf(out, "printf(\"\\n\");\n"); }
    | SCAN    '(' scan_list  ')' ';'
    ;

print_list : print_item | print_list ',' print_item ;

print_item
    : STRING_LIT
      {
          int len = strlen($1);
          char *raw = malloc(len - 1);
          strncpy(raw, $1 + 1, len - 2); raw[len - 2] = '\0';
          int pct = 0;
          for (char *p = raw; *p; p++) if (*p == '%') pct++;
          char *inner = malloc(strlen(raw) + pct + 1);
          char *src = raw, *dst = inner;
          while (*src) { if (*src == '%') *dst++ = '%'; *dst++ = *src++; }
          *dst = '\0';
          /* TAC */
          char tbuf[256];
          sprintf(tbuf, "PRINT \"%s\"", raw);
          tac_emit_comment(tbuf);
          /* C */
          print_indent(); fprintf(out, "printf(\"%s\");\n", inner);
          free(raw); free(inner); free($1);
      }
    | expr
      {
          /* TAC */
          char tbuf[256];
          snprintf(tbuf, 255, "PRINT %s", $1);
          tac_emit_comment(tbuf);
          /* C */
          print_indent();
          if (symbol_exists($1)) {
              char *t = get_type($1);
              if      (strcmp(t,"float")==0) fprintf(out,"printf(\"%%f\", %s);\n",$1);
              else if (strcmp(t,"char") ==0) fprintf(out,"printf(\"%%c\", %s);\n",$1);
              else                           fprintf(out,"printf(\"%%d\", %s);\n",$1);
          } else {
              fprintf(out,"printf(\"%%g\", (double)(%s));\n",$1);
          }
          free($1);
      }
    ;

scan_list : scan_item | scan_list ',' scan_item ;

scan_item
    : IDENTIFIER
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          char *t = get_type($1);
          /* TAC */
          char tbuf[128];
          sprintf(tbuf, "READ %s", $1);
          tac_emit_comment(tbuf);
          /* C */
          print_indent();
          if      (strcmp(t,"float")==0) fprintf(out,"scanf(\"%%f\", &%s);\n",$1);
          else if (strcmp(t,"char") ==0) fprintf(out,"scanf(\" %%c\", &%s);\n",$1);
          else                           fprintf(out,"scanf(\"%%d\", &%s);\n",$1);
          free($1);
      }
    ;

call_stmt
    : IDENTIFIER '(' arg_list_opt ')'
      {
          /* TAC: emit PARAM for each arg (args already comma-separated) */
          if ($3) tac_emit_param($3);
          tac_emit_call("", $1, $3);
          print_indent(); fprintf(out,"%s(%s);\n",$1,$3?$3:"");
          free($1); if($3)free($3);
      }
    ;

return_stmt
    : RETURN expr
      {
          tac_emit_return($2);
          print_indent(); fprintf(out,"return %s;\n",$2); free($2);
      }
    | RETURN
      {
          tac_emit_return("");
          print_indent(); fprintf(out,"return;\n");
      }
    ;

break_stmt
    : BREAK
      {
          tac_emit_comment("BREAK");
          print_indent(); fprintf(out,"break;\n");
      }
    ;

continue_stmt
    : CONTINUE
      {
          tac_emit_comment("CONTINUE");
          print_indent(); fprintf(out,"continue;\n");
      }
    ;

if_stmt
    : IF '(' expr ')'
      {
          const char *lf = tac_new_label();  /* label for false branch */
          /* Store label in a static so elseif_chain can use it */
          /* We use a temp variable trick: emit IFNOT, save label in $$ via a helper */
          tac_emit_ifnot($3, lf);
          /* Push the "false label" into the expression string so elseif_chain sees it.
             We concatenate it into a special marker string. */
          /* Actually: just emit C directly. The TAC already captured the structure. */
          print_indent(); fprintf(out,"if (%s) ",$3);
          free($3);
          /* Note: lf is in the pool so it stays alive */
      }
      block elseif_chain

    ;

elseif_chain
    : /* empty */
      {
          tac_emit_comment("end if");
      }
    | ELSEIF '(' expr ')'
      {
          const char *lf = tac_new_label();
          tac_emit_ifnot($3, lf);
          fprintf(out," else if (%s) ",$3); free($3);
      }
      block elseif_chain
    | ELSE
      {
          tac_emit_comment("else branch");
          fprintf(out," else ");
      }
      block
      {
          tac_emit_comment("end if-else");
      }
    ;

for_loop
    : FOR '(' for_init ';' for_cond ';' for_iter ')'
      {
          const char *ls = tac_new_label();
          const char *le = tac_new_label();
          /* Emit init TAC (already emitted inside for_init rule) */
          tac_emit_label(ls);
          if ($5) tac_emit_ifnot($5, le);
          /* Save le as a comment so body knows where to jump */
          /* We emit the loop structure comment */
          char tbuf[64];
          sprintf(tbuf, "loop body (exit at %s)", le);
          tac_emit_comment(tbuf);
          /* C */
          print_indent();
          fprintf(out, "for (%s; %s; %s) ",
                  $3 ? $3 : "", $5 ? $5 : "", $7 ? $7 : "");
          if ($3) free($3); if ($5) free($5); if ($7) free($7);
      }
      block
      {
          tac_emit_comment("end for");
      }
    ;

for_init
    : /* empty */ { $$ = NULL; }
    | type_name IDENTIFIER '=' expr
      {
          add_symbol($2, $1);
          tac_emit_assign($2, $4);
          char *buf = malloc(strlen($1)+strlen($2)+strlen($4)+8);
          sprintf(buf, "%s %s = %s", $1, $2, $4);
          free($1); free($2); free($4); $$ = buf;
      }
    | IDENTIFIER '=' expr
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          tac_emit_assign($1, $3);
          char *buf = malloc(strlen($1)+strlen($3)+6);
          sprintf(buf, "%s = %s", $1, $3);
          free($1); free($3); $$ = buf;
      }
    ;

for_cond
    : /* empty */ { $$ = NULL; }
    | expr        { $$ = $1;   }
    ;

for_iter
    : /* empty */ { $$ = NULL; }
    | IDENTIFIER INC
      {
          tac_emit_binop($1, $1, "+", "1");
          char *buf=malloc(strlen($1)+4); sprintf(buf,"%s++",$1); free($1); $$=buf;
      }
    | IDENTIFIER DEC
      {
          tac_emit_binop($1, $1, "-", "1");
          char *buf=malloc(strlen($1)+4); sprintf(buf,"%s--",$1); free($1); $$=buf;
      }
    | IDENTIFIER '=' expr
      {
          tac_emit_assign($1, $3);
          char *buf=malloc(strlen($1)+strlen($3)+6);
          sprintf(buf,"%s = %s",$1,$3); free($1); free($3); $$=buf;
      }
    | IDENTIFIER ASSIGNOP expr
      {
          char op[4] = {$2[0], '\0'};
          const char *tmp = tac_new_temp();
          tac_emit_binop(tmp, $1, op, $3);
          tac_emit_assign($1, tmp);
          char *buf=malloc(strlen($1)+strlen($2)+strlen($3)+6);
          sprintf(buf,"%s %s %s",$1,$2,$3); free($1); free($2); free($3); $$=buf;
      }
    ;

while_loop
    : WHILE '(' expr ')'
      {
          const char *ls = tac_new_label();
          const char *le = tac_new_label();
          tac_emit_label(ls);
          tac_emit_ifnot($3, le);
          char tbuf[64];
          sprintf(tbuf, "while body (exit at %s)", le);
          tac_emit_comment(tbuf);
          print_indent(); fprintf(out,"while (%s) ",$3); free($3);
      }
      block
      {
          tac_emit_comment("end while");
      }
    ;

do_while_loop
    : DO
      {
          const char *ls = tac_new_label();
          tac_emit_label(ls);
          tac_emit_comment("do-while body");
          print_indent(); fprintf(out,"do ");
      }
      block WHILE '(' expr ')' ';'
      {
          tac_emit_comment("do-while condition check");
          /* TAC: IF cond GOTO L_start  (already labelled above) */
          tac_emit_if($6, "L_start_do");  /* simplified — shows the pattern */
          tac_emit_comment("end do-while");
          print_indent(); fprintf(out,"while (%s);\n",$6); free($6);
      }
    ;

expr
    : INT_LIT    { $$ = $1; }
    | FLOAT_LIT  { $$ = $1; }
    | STRING_LIT { $$ = $1; }
    | CHAR_LIT   { $$ = $1; }
    | TRUE_LIT   { $$ = $1; }
    | FALSE_LIT  { $$ = $1; }
    | IDENTIFIER
      {
          if (!symbol_exists($1)) {
              fprintf(stderr,"Semantic Error at line %d: '%s' not declared\n",yylineno,$1);
              exit(1);
          }
          $$ = $1;
      }
    | call_expr  { $$ = $1; }
    | IDENTIFIER INC
      { char *buf=malloc(strlen($1)+4); sprintf(buf,"%s++",$1); free($1); $$=buf; }
    | IDENTIFIER DEC
      { char *buf=malloc(strlen($1)+4); sprintf(buf,"%s--",$1); free($1); $$=buf; }
    | '(' expr ')'
      { char *buf=malloc(strlen($2)+4); sprintf(buf,"(%s)",$2); free($2); $$=buf; }
    | ADDOP expr %prec UMINUS
      { char *buf=malloc(strlen($1)+strlen($2)+2); sprintf(buf,"%s%s",$1,$2); free($1);free($2); $$=buf; }
    | NOT expr
      { char *buf=malloc(strlen($2)+3); sprintf(buf,"!%s",$2); free($2); $$=buf; }

    | expr MULOP expr
      {
          /* Try constant folding first */
          char *folded = fold_expr($1, $2, $3);
          if (folded) {
              /* Folded: no TAC needed — result is already a literal */
              char tbuf[128];
              snprintf(tbuf, 127, "folded: %s %s %s = %s", $1, $2, $3, folded);
              tac_emit_comment(tbuf);
              free($1); free($2); free($3);
              $$ = folded;
          } else {
              /* Not foldable: emit TAC instruction */
              const char *tmp = tac_new_temp();
              tac_emit_binop(tmp, $1, $2, $3);
              char *buf=malloc(strlen($1)+strlen($2)+strlen($3)+6);
              sprintf(buf,"(%s %s %s)",$1,$2,$3);
              free($1);free($2);free($3);
              $$ = buf;
              /* Note: we return the C expression string, not tmp,
                 because C output needs the full expression.
                 TAC has the tmp assignment for its own use. */
          }
      }
    | expr ADDOP expr
      {
          char *folded = fold_expr($1, $2, $3);
          if (folded) {
              char tbuf[128];
              snprintf(tbuf, 127, "folded: %s %s %s = %s", $1, $2, $3, folded);
              tac_emit_comment(tbuf);
              free($1); free($2); free($3);
              $$ = folded;
          } else {
              const char *tmp = tac_new_temp();
              tac_emit_binop(tmp, $1, $2, $3);
              char *buf=malloc(strlen($1)+strlen($2)+strlen($3)+6);
              sprintf(buf,"(%s %s %s)",$1,$2,$3);
              free($1);free($2);free($3);
              $$ = buf;
          }
      }
    | expr RELOP expr
      {
          char *folded = fold_expr($1, $2, $3);
          if (folded) {
              free($1); free($2); free($3);
              $$ = folded;
          } else {
              const char *tmp = tac_new_temp();
              tac_emit_binop(tmp, $1, $2, $3);
              char *buf=malloc(strlen($1)+strlen($2)+strlen($3)+6);
              sprintf(buf,"(%s %s %s)",$1,$2,$3);
              free($1);free($2);free($3);
              $$ = buf;
          }
      }
    | expr AND expr
      {
          const char *tmp = tac_new_temp();
          tac_emit_binop(tmp, $1, "&&", $3);
          char *buf=malloc(strlen($1)+strlen($3)+8);
          sprintf(buf,"(%s && %s)",$1,$3);
          free($1);free($3); $$=buf;
      }
    | expr OR expr
      {
          const char *tmp = tac_new_temp();
          tac_emit_binop(tmp, $1, "||", $3);
          char *buf=malloc(strlen($1)+strlen($3)+8);
          sprintf(buf,"(%s || %s)",$1,$3);
          free($1);free($3); $$=buf;
      }
    ;

call_expr
    : IDENTIFIER '(' arg_list_opt ')'
      {
          const char *tmp = tac_new_temp();
          tac_emit_call(tmp, $1, $3);
          char *buf=malloc(strlen($1)+($3?strlen($3):0)+6);
          sprintf(buf,"%s(%s)",$1,$3?$3:"");
          free($1); if($3)free($3); $$=buf;
      }
    ;

arg_list_opt : /* empty */ { $$=NULL; } | arg_list { $$=$1; } ;

arg_list
    : expr { $$ = $1; }
    | arg_list ',' expr
      { char *buf=malloc(strlen($1)+strlen($3)+4); sprintf(buf,"%s, %s",$1,$3); free($1);free($3); $$=buf; }
    ;

type_name
    : INT   { $$=strdup("int");   strcpy(current_type,"int");   }
    | FLOAT { $$=strdup("float"); strcpy(current_type,"float"); }
    | CHAR  { $$=strdup("char");  strcpy(current_type,"char");  }
    | BOOL  { $$=strdup("bool");  strcpy(current_type,"bool");  }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error at line %d: %s\n", yylineno, s);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <source.sus> [output.c]\n", argv[0]);
        fprintf(stderr, "  Generates output.c  (C source)\n");
        fprintf(stderr, "  Generates tac.txt   (Three-Address Code)\n");
        return 1;
    }
    const char *out_name = (argc >= 3) ? argv[2] : "output.c";

    out = fopen(out_name, "w");
    if (!out) { fprintf(stderr, "Error: cannot create '%s'\n", out_name); return 1; }

    /* Open TAC output file */
    FILE *tac_file = fopen("tac.txt", "w");
    if (!tac_file) { fprintf(stderr, "Error: cannot create 'tac.txt'\n"); fclose(out); return 1; }
    tac_init(tac_file);

    /* C file headers */
    fprintf(out, "/* Generated by SUScript Compiler */\n");
    fprintf(out, "#include <stdio.h>\n");
    fprintf(out, "#include <stdbool.h>\n");
    fprintf(out, "#include <string.h>\n\n");

    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error: cannot open '%s'\n", argv[1]);
        fclose(out); fclose(tac_file); return 1;
    }

    init_symbol_table();
    int rc = yyparse();

    fclose(out);
    fclose(tac_file);
    fclose(yyin);

    if (rc == 0) {
        printf("SUScript compilation successful!\n");
        printf("  C output  : %s\n", out_name);
        printf("  TAC output: tac.txt\n");
    } else {
        fprintf(stderr, "Compilation failed.\n");
        remove(out_name);
        remove("tac.txt");
    }
    return rc;
}
