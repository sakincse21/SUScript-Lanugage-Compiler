#include "constant_fold.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// integer literal check
static int is_int_lit(const char *s) {
    if (!s || !*s) return 0;
    const char *p = s;
    if (*p == '-') p++;
    if (!*p) return 0;
    while (*p) {
        if (!isdigit((unsigned char)*p)) return 0;
        p++;
    }
    return 1;
}

// float literal check
static int is_float_lit(const char *s) {
    if (!s || !*s) return 0;
    const char *p = s;
    if (*p == '-') p++;
    int has_dot = 0, has_digit = 0;
    while (*p) {
        if (*p == '.') { has_dot = 1; }
        else if (isdigit((unsigned char)*p)) { has_digit = 1; }
        else return 0;
        p++;
    }
    return has_dot && has_digit;
}

char *fold_expr(const char *left, const char *op, const char *right) {
    if (!left || !op || !right) return NULL;

    int  li = is_int_lit(left),   ri = is_int_lit(right);
    int  lf = is_float_lit(left), rf = is_float_lit(right);

    if (!li && !lf) return NULL;
    if (!ri && !rf) return NULL;

    char *result = malloc(64);
    if (!result) return NULL;

    // if any side is float, folding in float
    if (lf || rf) {
        double L = atof(left);
        double R = atof(right);
        double V = 0;
        int    is_rel = 0;
        int    rel_v  = 0;

        if      (strcmp(op, "+") == 0) V = L + R;
        else if (strcmp(op, "-") == 0) V = L - R;
        else if (strcmp(op, "*") == 0) V = L * R;
        else if (strcmp(op, "/") == 0) {
            // division by zero check
            if (R == 0.0) { free(result); return NULL; }
            V = L / R;
        }
        else if (strcmp(op, "==") == 0) { is_rel=1; rel_v=(L==R); }
        else if (strcmp(op, "!=") == 0) { is_rel=1; rel_v=(L!=R); }
        else if (strcmp(op, "<")  == 0) { is_rel=1; rel_v=(L< R); }
        else if (strcmp(op, ">")  == 0) { is_rel=1; rel_v=(L> R); }
        else if (strcmp(op, "<=") == 0) { is_rel=1; rel_v=(L<=R); }
        else if (strcmp(op, ">=") == 0) { is_rel=1; rel_v=(L>=R); }
        else { free(result); return NULL; }

        if (is_rel) snprintf(result, 64, "%d", rel_v);
        else        snprintf(result, 64, "%g", V);
        return result;
    }

    // both sides are integer literals, folding in integer
    {
        long L = atol(left);
        long R = atol(right);
        long V = 0;
        int  is_rel = 0, rel_v = 0;

        if      (strcmp(op, "+") == 0) V = L + R;
        else if (strcmp(op, "-") == 0) V = L - R;
        else if (strcmp(op, "*") == 0) V = L * R;
        else if (strcmp(op, "/") == 0) {
            // division by zero check
            if (R == 0) { free(result); return NULL; }
            V = L / R;
        }
        else if (strcmp(op, "%") == 0) {
            // mod by zero check
            if (R == 0) { free(result); return NULL; }
            V = L % R;
        }
        else if (strcmp(op, "==") == 0) { is_rel=1; rel_v=(L==R); }
        else if (strcmp(op, "!=") == 0) { is_rel=1; rel_v=(L!=R); }
        else if (strcmp(op, "<")  == 0) { is_rel=1; rel_v=(L< R); }
        else if (strcmp(op, ">")  == 0) { is_rel=1; rel_v=(L> R); }
        else if (strcmp(op, "<=") == 0) { is_rel=1; rel_v=(L<=R); }
        else if (strcmp(op, ">=") == 0) { is_rel=1; rel_v=(L>=R); }
        else { free(result); return NULL; }

        if (is_rel) snprintf(result, 64, "%d", rel_v);
        else        snprintf(result, 64, "%ld", V);
        return result;
    }
}
