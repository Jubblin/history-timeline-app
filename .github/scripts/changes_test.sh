#!/bin/sh
# Tests for changes.sh. Run: sh .github/scripts/changes_test.sh
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
fail=0

# check NAME GO PATHS...   (PATHS are joined with newlines)
check() {
	name=$1 want="go=$2"
	shift 2
	got=$(
		if [ $# -gt 0 ]; then printf '%s\n' "$@"; fi | sh "$here/changes.sh" | tr '\n' ' ' | sed 's/ $//'
	)
	if [ "$got" = "$want" ]; then
		echo "ok   $name"
	else
		echo "FAIL $name: got '$got' want '$want'"
		fail=1
	fi
}

check "README only" false README.md
check "root docs and license" false CONTRIBUTING.md SECURITY.md LICENSE
check "devcontainer only" false .devcontainer/devcontainer.json
check "cmd only" true cmd/history-timeline/main.go
check "internal go only" true internal/store/store.go
check "go.mod" true go.mod
check "go.sum" true go.sum
check "web only" true web/static/app.js
check "Makefile" true Makefile
check ".gitattributes" true .gitattributes
check "workflow" true .github/workflows/ci.yml
check "renovate config" true renovate.json
check "mix docs and go" true README.md cmd/x/main.go
check "markdown under internal counts as Go" true internal/foo/README.md
check "empty list runs everything" true
check "unknown file runs everything" true .golangci.yml
check "path with spaces" true "internal/my dir/a b.go"
check "quoted unusual path runs everything" true '"internal/caf\303\251.go"'
check "unicode path" true "internal/café/é.go"
check "path with dollar and quote chars" true "web/\$x'y.js"
check "blank lines ignored" false "" README.md ""

# detect.sh: a rename out of a Go file into a docs path must still run Go.
repo=$(mktemp -d)
(
	cd "$repo"
	git init -q
	git config user.email t@example.invalid
	git config user.name t
	mkdir internal
	printf 'package x\n\nfunc A() {}\nfunc B() {}\nfunc C() {}\n' >internal/x.go
	git add -A
	git commit -qm one
	git mv internal/x.go NOTES.md
	git commit -qm two
	got=$(EVENT_NAME=push BEFORE_SHA=$(git rev-parse HEAD~1) HEAD_SHA=$(git rev-parse HEAD) sh "$here/detect.sh" | tr '\n' ' ')
	case $got in
	*go=true*) echo "ok   rename of a Go file to markdown runs Go" ;;
	*) echo "FAIL rename of a Go file to markdown: $got"; exit 1 ;;
	esac
) || fail=1
rm -rf "$repo"

exit $fail
