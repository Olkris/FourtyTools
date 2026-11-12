SELF 		:= $(firstword $(MAKEFILE_LIST))

DIR 		?= .
FILE 		?= $(wildcard $(DIR)/*.c)

CFLAGS 		?= -Wall -Wextra -Werror -g -Wpointer-arith
NO_COMP 	:= -fsyntax-only
NULL_COMP 	:= -c -o /dev/null
MODE 		?= full

default: sentinel 

compile:
	@$(if $(wildcard $(DIR)/Makefile), \
		printf "\033[1;92mUsing project's own Makefile:\033[0m\n" && \
		$(MAKE) --no-print-directory -C $(DIR), \
		printf "\033[1;33mNo Makefile found, dry compiling single file:\033[0m\n" && \
		$(CC) $(CFLAGS) $(if $(filter fast,$(MODE)),$(NO_COMP),$(NULL_COMP)) $(FILE) \
		)

norminette:
	@norminette $(FILE)

sentinel:
	@inotifywait . -mr -e close_write -e moved_to --include '\.(c|h)$$' | while read -r DIR EVENT FILE; do \
		clear && make -f $(SELF) --no-print-directory compile norminette DIR="$$DIR" FILE="$$DIR$$FILE"; \
	done 

review:
	@echo "Not implemented yet"

.PHONY: default compile norminette sentinel review
