#ifndef CONSTANT_FOLD_H
#define CONSTANT_FOLD_H


// compile time folding of binary expressions with literals
char *fold_expr(const char *left, const char *op, const char *right);

#endif
