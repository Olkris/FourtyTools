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



REPO_URL := https://raw.githubusercontent.com/Olkris/FourtyTools/main

update:
	@printf "\033[1;34mUpdating 42l...\033[0m\n"
	@curl -fsSL "$(REPO_URL)/42l.mk" -o "$(HOME)/.local/share/42l/42l.mk"
	@curl -fsSL "$(REPO_URL)/42l.sh" -o "$(HOME)/.local/bin/42l"
	@chmod +x "$(HOME)/.local/bin/42l"
	@printf "\033[1;32m42l is up to date!\033[0m\n"

.PHONY: default compile norminette sentinel review update
