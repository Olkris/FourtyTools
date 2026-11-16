#!/bin/sh

42L_MK="$HOME/.42l/42l.mk"

if [ ! -f "$42L_MK" ]; then
    printf "\033[1;31mError:\033[0m %s not found. Run install.sh first.\n" "$42L_MK" >&2
    exit 1
fi

exec make -f "$42L_MK" --no-print-directory "$@"
