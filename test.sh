#!/usr/bin/env bash

set -euf -o pipefail

# Get the project name from the current directory.
project_name="$(basename "$(pwd)")"

echo "==================== TESTING ${project_name^^} ====================="
echo "Starting comprehensive code quality checks..."
echo

echo "==================== SHELL FORMAT CHECK ==============="
echo "Checking if shell files are properly formatted..."
unformatted_files=$(find . -path ./.git -prune -o -type f -exec sh -c 'file "$1" | grep -q "shell script" && shfmt -d "$1"' _ {} \; 2>&1 | grep -v "No such file or directory" || true)
if [ -n "$unformatted_files" ]; then
	echo "✗ Some files were not properly formatted:"
	echo "$unformatted_files"
	echo "Files need to be formatted with 'shfmt -w'"
	exit 1
fi
echo "✓ All shell files are properly formatted"
echo

echo "==================== SHELLCHECK ======================"
echo "Running shellcheck for static analysis..."
find . -path ./.git -prune -o -type f -exec sh -c 'file "$1" | grep -q "shell script" && shellcheck -x "$1"' _ {} \;
echo "✓ 'shellcheck' passed"
echo

echo "==================== TRIVY SCAN ======================"
echo "Running Trivy scan for vulnerabilities, misconfigurations, secrets, and licenses..."
trivy filesystem --scanners vuln,misconfig,secret,license --license-full \
	--ignored-licenses Apache-2.0 \
	--quiet ./
echo "✓ Trivy scan passed"
echo
echo "==================== ALL CHECKS PASSED ==============="
