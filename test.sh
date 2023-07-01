#!/usr/bin/env bash

shellcheck \
	scripts/archive-converter.sh \
	.bash_functions \
	.profile \
	deploy.sh
