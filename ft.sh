#!/bin/bash

# ==========================================
# INIT SECTION
# ==========================================

trap cleanup INT TERM

# ==========================================
# NAMED LOGIC BLOCKS
# ==========================================

cleanup() {
	tput rmcup
	clear
	echo -e "\n\033[1;33m[Closed FourtyTool]\033[0m"
	exit 0
}

# ==========================================
# FUNCTIONS FOR DIFFERENT MODES
# ==========================================

mode_review() {
	clear
	tree
	read -e -p "Press Enter to continue..." </dev/tty

	clear 
	norminette
	read -e -p "Press Enter to continue..." </dev/tty

	clear
	find -mindepth 1 -type d -name "ex*" | sort -V | while read -r DIR; do
		clear
		FILES=("$DIR"/*.c)
	    [ -e "${FILES}" ] || { read -e -p "Directory $DIR is empty" </dev/tty; continue; }
	
		bat "$DIR/"*.c --paging=never

		cat "$DIR/"*.c | perl -0777 -pe 's|//\s*(#include\s*<.*?>)|$1|g; s|/\*(\s*(?:(?!\*/).)*?int\smain.*?)\*/|$1|gs' | \
			cc -Wall -Wextra -Werror -x c - -o "$DIR/a.out" 2>/tmp/compile_err

		if [ ! -f "$DIR/a.out" ]; then
			echo -e "\n\033[1;31m[Compilation Failed]\033[0m"
			cat /tmp/compile_err
			read -e -p "Press Enter to skip to next exercise..." </dev/tty
			continue
		fi

		while true; do
			echo -e "\n\033[1;34m==================== [ $DIR ] ====================\033[0m"
			# read -raw -editor -prompt
			read -r -e -p "Enter arguments (or 'n' for next, 'q' to quit): " ARGS </dev/tty

			if [ "$ARGS" = "n" ]; then
				break
			elif [ "$ARGS" = "q" ]; then
				rm -f "$DIR/a.out"
				[ -d "../review" ] && { cd .. && rm -rf review; }
				exit 0
			fi

			clear
			bat "$DIR"/*.c --paging=never
			echo -e "\n\033[1;32mRunning with args:\033[0m $ARGS"
			echo -e "\n\033[1;33m--- Output ---\033[0m"
	
			# Run in a subshell so Ctrl+C doesn't kill the parent script
			(
				# Reset the Ctrl+C trap inside the subshell so it kills ONLY this binary
				trap 'exit 130' INT
				eval "\"$DIR/a.out\" $ARGS" </dev/tty
			)
	
			# Capture if the subshell was interrupted (Exit code 130 means Ctrl+C was pressed)
			if [ $? -eq 130 ]; then
				echo -e "\n\033[1;31m[Execution Interrupted by User]\033[0m"
			fi
		done
		rm "$DIR"/a.out 2>/dev/null
	done
}

git_review_wrapper() {
	local REPO_URL="$1"
	
	git clone "$REPO_URL" review
	cd review

	mode_review

	cd ..
	rm -rf review
}

mode_sentinel() {
	clear
	echo -e "\033[1;35m[Dev sentinel launched]\033[0m"
	inotifywait --include '\.c$' -mre modify . | while read -r DIR EVENT FILE; do
		clear
		cat "$DIR"*.c | perl -0777 -pe 's|//\s*(#include\s*<.*?>)|$1|g; s|/\*(\s*(?:(?!\*/).)*?int\smain.*?)\*/|$1|gs' | \
			cc -Wall -Wextra -Werror -x c - && norminette "$DIR/$FILE"
	done
}

# ==========================================
# REUSABLE PRINT BLOCKS
# ==========================================

print_usage() {
cat << EOF
Usage:
    ft [r|review|clone] [<url>]    - Quickly review other students' projects"
    ft [s|sentinel]                - Automatic compile & norminette on code change"
EOF
}

# ==========================================
# MAIN FUNCTION (MODE ROUTER)
# ==========================================

MODE=$1

case "$MODE" in
	"sentinel" | "s")
		mode_sentinel
		;;
	"review" | "r" | "clone")
		clear
		REPO_URL="$2"

		if [ -z "$REPO_URL" ]; then
			echo -e "\033[1;34m[Review mode launched]\033[0m"
			read -e -p "Enter git repo URL (or leave blank to review current directory): " REPO_URL </dev/tty
		fi

		if [ -z "$REPO_URL" ]; then
			mode_review
			clear
			echo -e "\033[1;38;5;40m[Review complete!]\033[0m\n"
		else
			git_review_wrapper "$REPO_URL"
			clear
			echo -e "\033[1;38;5;40m[Review complete! Cleared out review directory automatically]\033[0m\n"
		fi
		;;
	"help" | "h" | "-h" | "--help")
		echo -e "\033[1;34mHelp page\033[0m"
		print_usage
		;;
	"")
		echo -e "\033[1;33mNo arguments provided\033[0m"
		print_usage
		;;
	*)
		echo -e "\033[1;31mError: Unknown mode '$MODE'\033[0m"
		print_usage
		exit 1
		;;
esac
