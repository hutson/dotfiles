#!/usr/bin/env bash

shellcheck \
	scripts/archive-converter.sh \
	scripts/flac-converter.sh \
	.bash_aliases \
	.bash_functions \
	.profile \
	deploy.sh
