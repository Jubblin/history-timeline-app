#!/bin/sh
# Decide which CI jobs a change needs.
#
# Reads changed paths, one per line, from stdin and prints
#   go=true|false
#
# Classification:
#   docs only, run nothing: markdown in the repository root, LICENSE,
#     .devcontainer/**
#   anything else runs the Go jobs, and so does an empty list, so a new kind of
#   file or an odd diff can never silently skip checks.
set -eu

go=false
seen=false

while IFS= read -r p || [ -n "$p" ]; do
	[ -n "$p" ] || continue
	seen=true
	case $p in
	.devcontainer/*) continue ;;
	*/*) ;;
	*.md | LICENSE) continue ;;
	esac
	go=true
done

if [ "$seen" = false ]; then
	go=true
fi
printf 'go=%s\n' "$go"
