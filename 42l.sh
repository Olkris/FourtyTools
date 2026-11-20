#!/bin/sh

FTL_MK="$HOME/.local/share/42l/42l.mk"

if [ ! -f "$FTL_MK" ]; then
    printf "\033[1;31mError:\033[0m %s not found. Run install.sh first.\n" "$FTL_MK" >&2
    exit 1
fi

exec make -f "$FTL_MK" --no-print-directory "$@"
