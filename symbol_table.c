#include "symbol_table.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_SYMBOLS 512

typedef struct {
    char name[64];
    char type[20];
    int  scope;
} Symbol;

static Symbol table[MAX_SYMBOLS];
static int    count = 0;
static int    current_scope = 0;

void init_symbol_table() {
    count = 0;
    current_scope = 0;
}

void push_scope() {
    current_scope++;
}

void pop_scope() {
    while (count > 0 && table[count-1].scope == current_scope)
        count--;
    if (current_scope > 0) current_scope--;
}

void add_symbol(const char *name, const char *type) {
    // duplicate checking in current scope
    for (int i = count-1; i >= 0; i--) {
        if (table[i].scope < current_scope) break;
        if (strcmp(table[i].name, name) == 0) {
            fprintf(stderr, "Warning: '%s' already declared in this scope\n", name);
            return;
        }
    }
    //overflow check
    if (count >= MAX_SYMBOLS) { fprintf(stderr, "Error: symbol table overflow\n"); exit(1); }
    strncpy(table[count].name, name, 63);
    strncpy(table[count].type, type, 19);
    table[count].scope = current_scope;
    count++;
}

int symbol_exists(const char *name) {
    for (int i = count-1; i >= 0; i--)
        if (strcmp(table[i].name, name) == 0) return 1;
    return 0;
}

char *get_type(const char *name) {
    for (int i = count-1; i >= 0; i--)
        if (strcmp(table[i].name, name) == 0) return table[i].type;
    return "unknown";
}

void print_symbol_table() {
    printf("\n--- Symbol Table ---\n");
    printf("%-20s %-10s %-5s\n", "Name", "Type", "Scope");
    for (int i = 0; i < count; i++)
        printf("%-20s %-10s %-5d\n", table[i].name, table[i].type, table[i].scope);
    printf("--------------------\n\n");
}
