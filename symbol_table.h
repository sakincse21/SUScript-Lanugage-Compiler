#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

void init_symbol_table();
void push_scope();
void pop_scope();
void add_symbol(const char *name, const char *type);
int  symbol_exists(const char *name);
char *get_type(const char *name);
void print_symbol_table();

#endif
