#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

function get_gpu_color() {

	gpu_medium_threshold=$(get_tmux_option "@sysstat_cpu_medium_threshold" "30")
	gpu_stress_threshold=$(get_tmux_option "@sysstat_cpu_stress_threshold" "80")

	gpu_color_low=$(get_tmux_option "@sysstat_cpu_color_low" "green")
	gpu_color_medium=$(get_tmux_option "@sysstat_cpu_color_medium" "yellow")
	gpu_color_stress=$(get_tmux_option "@sysstat_cpu_color_stress" "red")

	local gpu_used=$1
	if fcomp "$gpu_stress_threshold" "$gpu_used"; then
		echo "$gpu_color_stress"
	elif fcomp "$gpu_medium_threshold" "$gpu_used"; then
		echo "$gpu_color_medium"
	else
		echo "$gpu_color_low"
	fi
}

function get_gpu_vendor() {
	# allow pipefail, not propagating error
	set +o pipefail
	if lspci | grep -q -i amd; then
		echo "AMD"
	elif lspci | grep -q -i nvidia; then
		echo "NVIDIA"
	elif lspci | grep -q -i intel; then
		# Even if there is a second GPU e.g intel, take the first dedicated one
		echo "INTEL"
	fi
	set -o pipefail
}

function print_gpu_pusage() {
	local gpu_pusage=""
	# shellcheck disable=SC2155
	readonly gpu_view_tmpl=$(get_tmux_option "@sysstat_gpu_view_tmpl" 'GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default] #{gpu.gbused}')
	# shellcheck disable=SC2155
	readonly gpu_extra_options=$(get_tmux_option "@sysstat_gpu_opts" '')
	# shellcheck disable=SC2155
	readonly vendor=$(get_gpu_vendor)

	case "$vendor" in
	AMD)
		gpu_info=$(
			# shellcheck disable=SC2086
			radeontop --dump - --limit 1 $gpu_extra_options |
				grep gpu
		)
		gpu_pusage=$(echo "$gpu_info" | awk '{print $5}' | sed 's/%,//')
		gpu_mb_usage=$(echo "$gpu_info" | awk '{print $28}' | sed 's/.[0-9]*mb,//')
		gpu_gb_usage=$(printf %.2f "$gpu_mb_usage"e-3)
		;;
	NVIDIA)
		gpu_pusage=$(

			# shellcheck disable=SC2086
			nvidia-smi -q -d UTILIZATION $gpu_extra_options |
				grep Gpu | awk '{print $3}'
		)
		;;
	INTEL)
		# TODO: add intel_top
		# echo INTEL
		;;
	Mesa/X.org)
		# NOTE: should be a non issue now
		# echo SSH
		;;
	esac

	if [[ -z "$gpu_pusage" ]]; then
		echo "$vendor"
	else
		local gpu_view="$gpu_view_tmpl"
		gpu_pusage_colored=$(get_gpu_color "$gpu_pusage")
		gpu_view="${gpu_view//'#{gpu.pused}'/$(printf "%.1f%%" "$gpu_pusage")}"
		gpu_view="${gpu_view//'#{gpu.color}'/$(echo "$gpu_pusage_colored" | awk '{print $1}')}"
		gpu_view="${gpu_view//'#{gpu.color2}'/$(echo "$gpu_pusage_colored" | awk '{ print $2 }')}"
		gpu_view="${gpu_view//'#{gpu.color3}'/$(echo "$gpu_pusage_colored" | awk '{ print $3 }')}"
		if [ -n "$gpu_gb_usage" ]; then
			gpu_view="${gpu_view//'#{gpu.gbused}'/"$gpu_gb_usage"GB}"
		else
			gpu_view='GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default]'
		fi
		echo "$gpu_view"
	fi
}

print_gpu_pusage
