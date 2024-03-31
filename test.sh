#!/usr/bin/env bash

shellcheck -x \
	scripts/archive-converter.sh \
	scripts/flac-converter.sh \
	.bash_aliases \
	.bash_functions \
	.bashrc \
	.profile \
	deploy.sh \
	test.sh

shfmt -d \
	scripts/archive-converter.sh \
	scripts/flac-converter.sh \
	.bash_aliases \
	.bash_functions \
	.bashrc \
	.profile \
	deploy.sh \
	test.sh
