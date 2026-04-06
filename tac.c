// three adress code generation

#include "tac.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FILE *tac_out = NULL;
static int   temp_count  = 0;
static int   label_count = 0;

#define MAX_NAMES 1024
static char *name_pool[MAX_NAMES];
static int   name_pool_idx = 0;

static const char *pool_store(char *s) {
    if (name_pool_idx < MAX_NAMES)
        name_pool[name_pool_idx++] = s;
    return s;
}

void tac_init(FILE *f) {
    tac_out = f;
    temp_count  = 0;
    label_count = 0;
    name_pool_idx = 0;
    fprintf(tac_out, "# SUScript Three-Address Code (TAC)\n");
    fprintf(tac_out, "# Format: result = arg1 op arg2\n");
    fprintf(tac_out, "#         GOTO / IF / IFNOT labels\n");
    fprintf(tac_out, "# ----------------------------------------\n\n");
}

const char *tac_new_temp(void) {
    char *buf = malloc(16);
    sprintf(buf, "t%d", temp_count++);
    return pool_store(buf);
}

const char *tac_new_label(void) {
    char *buf = malloc(16);
    sprintf(buf, "L%d", label_count++);
    return pool_store(buf);
}

void tac_emit_binop(const char *result, const char *a1, const char *op, const char *a2) {
    if (!tac_out) return;
    fprintf(tac_out, "    %s = %s %s %s\n", result, a1, op, a2);
}

void tac_emit_assign(const char *result, const char *src) {
    if (!tac_out) return;
    fprintf(tac_out, "    %s = %s\n", result, src);
}

void tac_emit_goto(const char *label) {
    if (!tac_out) return;
    fprintf(tac_out, "    GOTO %s\n", label);
}

void tac_emit_if(const char *cond, const char *label) {
    if (!tac_out) return;
    fprintf(tac_out, "    IF %s GOTO %s\n", cond, label);
}

void tac_emit_ifnot(const char *cond, const char *label) {
    if (!tac_out) return;
    fprintf(tac_out, "    IFNOT %s GOTO %s\n", cond, label);
}

void tac_emit_label(const char *label) {
    if (!tac_out) return;
    fprintf(tac_out, "%s:\n", label);
}

void tac_emit_call(const char *result, const char *func, const char *args) {
    if (!tac_out) return;
    if (result && result[0])
        fprintf(tac_out, "    %s = CALL %s  [args: %s]\n", result, func, args ? args : "");
    else
        fprintf(tac_out, "    CALL %s  [args: %s]\n", func, args ? args : "");
}

void tac_emit_return(const char *val) {
    if (!tac_out) return;
    if (val && val[0])
        fprintf(tac_out, "    RETURN %s\n", val);
    else
        fprintf(tac_out, "    RETURN\n");
}

void tac_emit_param(const char *arg) {
    if (!tac_out) return;
    fprintf(tac_out, "    PARAM %s\n", arg);
}

void tac_emit_comment(const char *text) {
    if (!tac_out) return;
    fprintf(tac_out, "# %s\n", text);
}
