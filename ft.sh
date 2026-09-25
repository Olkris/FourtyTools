#!/bin/bash

# ==========================================
# REUSABLE PRINT BLOCKS
# ==========================================

print_usage() {
cat << EOF
Usage:
    ft [r|review|clone] [<url>]    - Quickly review other students' projects"
    ft [s|sentinel]                - Automatic compile & norminette on code change"

Review mode keywords :
    n              - Next review step / next exercise
    p              - previous review step / previous exercise
    q              - Quit review cleanly and run program cleanup code
    noflag         - Try compiling without flags
    debug perl     - Print the perl regex output for debug purposes
EOF
}

# ==========================================
# NAMED LOGIC BLOCKS
# ==========================================

disclose_command() {
	USED_COMMAND=$*
	echo -e "\033[33mCommand used:\033[0m > $USED_COMMAND\n"
}

show_navigation_prompt() {
	PROMPT_TEXT=${1:-Press Enter to continue...}
	echo # auto \n
	# read --raw --editor-mode --prompt
	read -r -e -p "$PROMPT_TEXT" ARGS </dev/tty
	if [ "$ARGS" = "n" ]; then
		(( STEP++ ))
	elif [ "$ARGS" = "p" ]; then 
		(( STEP-- ))
	elif [ "$ARGS" = "q" ]; then
		(( STEP = $EXERCISE_COUNT ))
	fi
}

show_file_tree() {
	local COMMAND=(tree --sort=version)
	disclose_command "${COMMAND[@]}"
	"${COMMAND[@]}"
}

check_norminette() {
	local COMMAND=(norminette -RCheckDefine)
	disclose_command "${COMMAND[@]}"
	"${COMMAND[@]}"
}

uncomment_code() {
	perl -0777 -pe 's|//\s*(#include\s*<.*?>)|$1|g; s|/\*(\s*(?:(?!\*/).)*?int\s*main.*?)\*/|$1|gs'
}

compile() {
	local COMMAND=(cc -g -O0 -x c -)	
	if [ "$1" != "noflags" ]; then
		COMMAND+=(-Wall -Wextra -Werror) 
	fi
	if [ -n "$2" ]; then
		COMMAND+=(-o "$2")
	fi
	disclose_command "${COMMAND[@]}"
	"${COMMAND[@]}"
}

check_norm() {
	local COMMAND=(norminette -RCheckDefine)
	disclose_command "${COMMAND[@]}"
	"${COMMAND[@]}"
}

cleanup() {
	tput rmcup
	clear
	echo -e "\033[1;33m[Closed FourtyTool]\033[0m\n"
	exit 0
}

# ==========================================
# FUNCTIONS FOR DIFFERENT MODES
# ==========================================

review_step_selector() {
	STEP=-2
	EXERCISE_COUNT=$(find -mindepth 1 -type d -name "ex*" | sort -V | wc -l)
	while (( $STEP < $EXERCISE_COUNT )); do
		clear
		echo -e "\033[1;34m[Review mode]\033[0m\n"

		if (( $STEP == -2 )); then
			show_file_tree
			show_navigation_prompt
			if [ "$ARGS" = "" ]; then (( STEP++ )) fi

		elif (( $STEP == -1 )); then
			check_norminette
			show_navigation_prompt
			if [ "$ARGS" = "" ]; then (( STEP++ )) fi

		elif (( $STEP >= 0 )); then
			DIR="ex$STEP"
			FILES=("$DIR"/*.c)

			if [ ! -e "${FILES}" ]; then
				echo -e "\033[1;31m[Directory $DIR is empty]\033[0m"
				show_navigation_prompt
				if [ "$ARGS" = "" ]; then (( STEP++ )) fi
				continue
			fi

			disclose_command "bat $FILES"
			bat "$FILES" --paging=never

			UNCOMMENTED_CODE=$(cat "${FILES[@]}" | uncomment_code)
			echo "$UNCOMMENTED_CODE" | compile withflags "$DIR/a.out" 2>/tmp/compile_err

			if [ ! -f "$DIR/a.out" ]; then
				echo -e "\n\033[1;31m[Compilation Failed]\033[0m"
				cat /tmp/compile_err
				show_navigation_prompt "Press Enter to skip to next exercise..."
				if [ "$ARGS" = "" ]; then 
					(( STEP++ ))
					continue
				elif [ "$ARGS" = "debug perl" ]; then
					clear
					echo "$UNCOMMENTED_CODE"
					show_navigation_prompt
					continue
				elif [ "$ARGS" = "noflag" ]; then
					echo "$UNCOMMENTED_CODE" | compile noflag "$DIR/a.out"
				fi
			fi

			while true; do
				echo -e "\n\033[1;34m==================== [ $DIR ] ====================\033[0m"
				show_navigation_prompt "Enter arguments (or 'n' for next, 'q' to quit): "
				if [ "$ARGS" = "n" ] || [ "$ARGS" = "p" ] || [ "$ARGS" = "q" ]; then
					break
				elif [ "$ARGS" = "debug perl" ]; then
					clear
					echo "$UNCOMMENTED_CODE"
					show_navigation_prompt
					continue
				else
					# Mini repeat of the print that occurred before this while loop, probably not the best solution
					clear
					echo -e "\033[1;34m[Review mode]\033[0m\n"
					disclose_command "bat $FILES"
					bat "$FILES" --paging=never
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
						show_navigation_prompt
						if [ "$ARGS" = "" ]; then (( STEP++ )) fi
						continue
					fi
				fi
			done
			#rm "$DIR/a.out" 2>/dev/null
		else
			# Step count is negative beyond -2, aka an invalid step
			clear
			echo -e "\033[1;31m[Tried to step backwards before step 1]\033[0m"		
			(( STEP++ ))
			show_navigation_prompt
		fi
		rm ./*/a.out 2>/dev/null
	done
}

git_review_wrapper() {
	local REPO_URL="$1"
	
	git clone "$REPO_URL" review
	cd review

	review_step_selector

	cd ..
	rm -rf review
}

mode_sentinel() {
	clear
	echo -e "\033[1;35m[Dev sentinel launched]\033[0m"
	inotifywait --include '\.c$' -mre modify . | while read -r DIR EVENT FILE; do
		clear
		cat "$DIR"*.c | uncomment_code | compile noflags && norminette "$DIR/$FILE"
	done
}

# ==========================================
# INIT SECTION
# ==========================================

trap cleanup INT TERM

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
			review_step_selector
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
