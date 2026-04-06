CC     = gcc
CFLAGS = -Wall -Wno-unused-variable -Wno-unused-but-set-variable -g
LEX    = flex
YACC   = bison
all: suscript
suscript.tab.c suscript.tab.h: suscript.y
	$(YACC) -d -v suscript.y
lex.yy.c: suscript.l suscript.tab.h
	$(LEX) suscript.l
suscript: lex.yy.c suscript.tab.c symbol_table.c constant_fold.c tac.c
	$(CC) $(CFLAGS) -o suscript lex.yy.c suscript.tab.c symbol_table.c constant_fold.c tac.c
t01: suscript
	@echo "=== TEST 01: Variables & Assignment ===" | tee test_01_variables_output.txt
	./suscript test_01_variables.sus _t.c 2>&1 | tee -a test_01_variables_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_01_variables_output.txt
	./_t 2>&1 | tee -a test_01_variables_output.txt
t02: suscript
	@echo "=== TEST 02: Arithmetic & Constant Folding ===" | tee test_02_arithmetic_output.txt
	./suscript test_02_arithmetic.sus _t.c 2>&1 | tee -a test_02_arithmetic_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_02_arithmetic_output.txt
	./_t 2>&1 | tee -a test_02_arithmetic_output.txt
	@echo "--- Generated C (shows folded constants) ---" | tee -a test_02_arithmetic_output.txt
	@cat _t.c | tee -a test_02_arithmetic_output.txt
t03: suscript
	@echo "=== TEST 03: Relational & Logical Operators ===" | tee test_03_relational_logical_output.txt
	./suscript test_03_relational_logical.sus _t.c 2>&1 | tee -a test_03_relational_logical_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_03_relational_logical_output.txt
	./_t 2>&1 | tee -a test_03_relational_logical_output.txt
t04: suscript
	@echo "=== TEST 04: If / Else-If / Else ===" | tee test_04_if_else_output.txt
	./suscript test_04_if_else.sus _t.c 2>&1 | tee -a test_04_if_else_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_04_if_else_output.txt
	./_t 2>&1 | tee -a test_04_if_else_output.txt
t05: suscript
	@echo "=== TEST 05: For Loop ===" | tee test_05_for_loop_output.txt
	./suscript test_05_for_loop.sus _t.c 2>&1 | tee -a test_05_for_loop_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_05_for_loop_output.txt
	./_t 2>&1 | tee -a test_05_for_loop_output.txt
t06: suscript
	@echo "=== TEST 06: While & Do-While ===" | tee test_06_while_dowhile_output.txt
	./suscript test_06_while_dowhile.sus _t.c 2>&1 | tee -a test_06_while_dowhile_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_06_while_dowhile_output.txt
	./_t 2>&1 | tee -a test_06_while_dowhile_output.txt
t07: suscript
	@echo "=== TEST 07: Functions ===" | tee test_07_functions_output.txt
	./suscript test_07_functions.sus _t.c 2>&1 | tee -a test_07_functions_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_07_functions_output.txt
	./_t 2>&1 | tee -a test_07_functions_output.txt
t08: suscript
	@echo "=== TEST 08: Input & Output (enter integer then float) ===" | tee test_08_input_output_output.txt
	./suscript test_08_input_output.sus _t.c 2>&1 | tee -a test_08_input_output_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_08_input_output_output.txt
	echo "7\n2.5" | ./_t 2>&1 | tee -a test_08_input_output_output.txt
t09: suscript
	@echo "=== TEST 09: Type System & Implicit Conversion ===" | tee test_09_type_system_output.txt
	./suscript test_09_type_system.sus _t.c 2>&1 | tee -a test_09_type_system_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_09_type_system_output.txt
	./_t 2>&1 | tee -a test_09_type_system_output.txt
t10: suscript
	@echo "=== TEST 10: Constant Folding ===" | tee test_10_constant_folding_output.txt
	./suscript test_10_constant_folding.sus _t.c 2>&1 | tee -a test_10_constant_folding_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_10_constant_folding_output.txt
	./_t 2>&1 | tee -a test_10_constant_folding_output.txt
	@echo "--- Generated C (see folded values) ---" | tee -a test_10_constant_folding_output.txt
	@cat _t.c | tee -a test_10_constant_folding_output.txt
t11: suscript
	@echo "=== TEST 11: Comments ===" | tee test_11_comments_output.txt
	./suscript test_11_comments.sus _t.c 2>&1 | tee -a test_11_comments_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a test_11_comments_output.txt
	./_t 2>&1 | tee -a test_11_comments_output.txt
t12: suscript
	@echo "=== TEST 12: Semantic Error Detection ===" | tee test_12_error_handling_output.txt
	./suscript test_12_error_handling.sus _t.c 2>&1 | tee -a test_12_error_handling_output.txt || true
testall: suscript
	@rm -f testall_output.txt
	@echo "=== TEST 01: Variables & Assignment ===" | tee -a testall_output.txt
	./suscript test_01_variables.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 02: Arithmetic & Constant Folding ===" | tee -a testall_output.txt
	./suscript test_02_arithmetic.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "--- Generated C (shows folded constants) ---" | tee -a testall_output.txt
	@cat _t.c | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 03: Relational & Logical Operators ===" | tee -a testall_output.txt
	./suscript test_03_relational_logical.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 04: If / Else-If / Else ===" | tee -a testall_output.txt
	./suscript test_04_if_else.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 05: For Loop ===" | tee -a testall_output.txt
	./suscript test_05_for_loop.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 06: While & Do-While ===" | tee -a testall_output.txt
	./suscript test_06_while_dowhile.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 07: Functions ===" | tee -a testall_output.txt
	./suscript test_07_functions.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 09: Type System & Implicit Conversion ===" | tee -a testall_output.txt
	./suscript test_09_type_system.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 10: Constant Folding ===" | tee -a testall_output.txt
	./suscript test_10_constant_folding.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "--- Generated C (see folded values) ---" | tee -a testall_output.txt
	@cat _t.c | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 11: Comments ===" | tee -a testall_output.txt
	./suscript test_11_comments.sus _t.c 2>&1 | tee -a testall_output.txt
	$(CC) -o _t _t.c 2>&1 | tee -a testall_output.txt
	./_t 2>&1 | tee -a testall_output.txt
	@echo "" | tee -a testall_output.txt
	@echo "=== TEST 12: Semantic Error Detection ===" | tee -a testall_output.txt
	./suscript test_12_error_handling.sus _t.c 2>&1 | tee -a testall_output.txt || true
	@echo "" | tee -a testall_output.txt
	@echo "=== All tests complete ===" | tee -a testall_output.txt
tac: suscript
	./suscript $(FILE) _t.c
	@echo "=== TAC Output ==="
	@cat tac.txt
clean:
	rm -f suscript _t _out output hello_out fold_demo_out
	rm -f lex.yy.c suscript.tab.c suscript.tab.h suscript.output
	rm -f _t.c _out.c output.c tac.txt
	rm -f test_*_output.txt testall_output.txt
.PHONY: all t01 t02 t03 t04 t05 t06 t07 t08 t09 t10 t11 t12 testall tac clean