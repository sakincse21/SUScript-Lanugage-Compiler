//three address code generation

#ifndef TAC_H
#define TAC_H

#include <stdio.h>

void tac_init(FILE *tac_file);

const char *tac_new_temp(void);

const char *tac_new_label(void);

void tac_emit_binop (const char *result, const char *a1, const char *op, const char *a2);
void tac_emit_assign(const char *result, const char *src);
void tac_emit_goto  (const char *label);
void tac_emit_if    (const char *cond,   const char *label);
void tac_emit_ifnot (const char *cond,   const char *label);
void tac_emit_label (const char *label);
void tac_emit_call  (const char *result, const char *func, const char *args);
void tac_emit_return(const char *val);
void tac_emit_param (const char *arg);
void tac_emit_comment(const char *text);

#endif
