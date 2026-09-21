#!/bin/bash

# ==========================================
# FUNCTIONS FOR DIFFERENT MODES
# ==========================================

# Core evaluation logic shared by both Full and Local modes
run_evaluation_loop() {
	clear
	tree
	read -p "Press Enter to continue..." </dev/tty

	clear 
	norminette
	read -p "Press Enter to continue..." </dev/tty

	clear
	find -mindepth 1 -type d -name "ex*" | sort -V | while read -r DIR; do
		clear
		FILES=("$DIR"/*.c)
	    [ -e "${FILES}" ] || { read -p "Directory $DIR is empty" </dev/tty; continue; }
	
		bat "$DIR/"*.c --paging=never

		cat "$DIR/"*.c | perl -0777 -pe 's|//\s*(#include\s*<.*?>)|$1|g; s|/\*(\s*(?:(?!\*/).)*?int\smain.*?)\*/|$1|gs' | \
			cc -Wall -Wextra -Werror -x c - -o "$DIR/a.out" 2>/tmp/compile_err

		if [ ! -f "$DIR/a.out" ]; then
			echo -e "\n\033[1;31m[Compilation Failed]\033[0m"
			cat /tmp/compile_err
			read -p "Press Enter to skip to next exercise..." </dev/tty
			continue
		fi

		while true; do
			echo -e "\n\033[1;34m==================== [ $DIR ] ====================\033[0m"
			read -e -p "Enter arguments (or 'n' for next, 'q' to quit): " ARGS </dev/tty

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
		clear
		rm "$DIR"/a.out 2>/dev/null
	done
}

mode_git_review() {
	local REPO_URL="$1"
	
	if [ -z "$REPO_URL" ]; then
		read -p "Git repo: " REPO_URL </dev/tty
	fi
	
	clear
	git clone "$REPO_URL" review
	cd review

	# Run the core evaluation logic
	run_evaluation_loop

	clear
	cd ..
	rm -rf review
	echo -e "\033[1;38;5;40m[Review complete! Cleared out review directory automatically]\033[0m\n"
}

mode_manual_review() {
	echo -e "\033[1;34m[Reviewing the current directory]\033[0m\n"

	# Run core logic directly in current folder
	run_evaluation_loop

	clear
	echo -e "\033[1;38;5;40m[Review complete!]\033[0m\n"
}

mode_dev_sentinel() {
	clear
	echo -e "\033[1;35m[Dev sentinel launched]\033[0m"
	inotifywait --include '\.c$' -mre modify . | while read -r DIR EVENT FILE; do
		clear
		cat "$DIR"*.c | perl -0777 -pe 's|//\s*(#include\s*<.*?>)|$1|g; s|/\*(\s*(?:(?!\*/).)*?int\smain.*?)\*/|$1|gs' | \
			cc -Wall -Wextra -Werror -x c - && norminette "$DIR/$FILE"
	done
}

# ==========================================
# MODE ROUTER (THE CASE STATEMENT)
# ==========================================

# If no argument is passed, default to "full"
MODE=${1:-review}

case "$MODE" in
	"sentinel" | "s")
		CURR_DIR="$PWD"
		mode_dev_sentinel
		;;
	"review" | "r" | "clone")
		clear
		REPO_URL="$2"

		if [ -z "$REPO_URL" ]; then
			echo -e "\033[1;34m[Review mode launched]\033[0m"
			read -p "Enter git repo URL (or leave blank to review current directory): " REPO_URL </dev/tty
		fi

		if [ -z "$REPO_URL" ]; then
			mode_manual_review
		else
			mode_git_review "$REPO_URL"
		fi
		;;
	*)
		echo -e "\033[1;31mError: Unknown mode '$MODE'\033[0m"
		cat << EOF
Usage:
	$0 [r|review|clone] [<url>]    - Quickly review other students' projects"
	$0 [s|sentinel]                - Automatic compile & norminette on code change"
EOF
		exit 1
		;;
esac
