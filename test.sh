#!/usr/bin/env bash

set -euf -o pipefail

# Get the project name from the current directory.
project_name="$(basename "$(pwd)")"

echo "==================== TESTING ${project_name^^} ===================="
echo "Starting comprehensive code quality checks..."
echo

echo "==================== SHELL FORMAT CHECK =============="
echo "Checking if shell files are properly formatted..."
unformatted_files=$(shfmt -d \
	scripts/archive-converter.sh \
	scripts/flac-converter.sh \
	.bash_aliases \
	.bash_functions \
	.bashrc \
	.profile \
	deploy.sh \
	test.sh 2>&1 || true)
if [ -n "$unformatted_files" ]; then
	echo "✗ Some files were not properly formatted:"
	echo "$unformatted_files"
	echo "Files need to be formatted with 'shfmt -w'"
	exit 1
fi
echo "✓ All shell files are properly formatted"
echo

echo "==================== SHELLCHECK ==================="
echo "Running shellcheck for static analysis..."
shellcheck -x \
	scripts/archive-converter.sh \
	scripts/flac-converter.sh \
	.bash_aliases \
	.bash_functions \
	.bashrc \
	.profile \
	deploy.sh \
	test.sh
echo "✓ 'shellcheck' passed"
echo

echo "==================== TRIVY SCAN ==================="
echo "Running Trivy scan for vulnerabilities, misconfigurations, secrets, and licenses..."
trivy filesystem --scanners vuln,misconfig,secret,license --license-full ./
echo "✓ Trivy scan passed"
echo

echo "==================== ALL CHECKS PASSED ============"
echo "✓ Code formatting, linting, and security scanning completed successfully"
