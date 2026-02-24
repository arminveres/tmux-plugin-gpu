#!/usr/bin/env bash

function fcomp() {
	awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<n2) exit 0; exit 1}'
}

function get_tmux_option() {
	set +u
	local option="$1"
	local default_value="$2"
	local option_value="$(tmux show-option -gqv "$option")"
	if [ -n "$option_value" ]; then
		echo "$option_value"
	else
		echo "$default_value"
	fi
	set -u
}

function set_tmux_option() {
	local option="$1"
	local value="$2"
	tmux set-option -gq "$option" "$value"
}
