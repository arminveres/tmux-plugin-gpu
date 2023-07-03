#!/usr/bin/env bash

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

vendor=''

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
	local amd=$(lspci | grep -i amd)
	local nvidia=$(lspci | grep -i nvidia)
	local intel=$(lspci | grep -i intel)

	if [[ -n $amd ]]; then
		vendor="AMD"
	elif [[ -n $nvidia ]]; then
		vendor="NVIDIA"
	elif [[ -n $intel ]]; then
		# NOTE: even if there is a second GPU e.g intel, take the first dedicated one
		vendor="INTEL"
	fi
}

function print_gpu_pusage() {
	local gpu_pusage=""
	local gpu_view_tmpl=$(get_tmux_option "@sysstat_gpu_view_tmpl" 'GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default] #{gpu.gbused}')

	case "$vendor" in
	AMD)
		gpu_info=$(radeontop -c -d - -l 1 | grep gpu)
		gpu_pusage=$(echo "$gpu_info" | awk '{print $5}' | sed 's/%,//')
		gpu_mb_usage=$(echo "$gpu_info" | awk '{print $28}' | sed 's/.[0-9]*mb,//')
		gpu_gb_usage=$(printf %.2f "$gpu_mb_usage"e-3)
		;;
	NVIDIA)
		gpu_pusage=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
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

	if [ -z "$gpu_pusage" ]; then
		echo $vendor
	else
		local gpu_view="$gpu_view_tmpl"
		gpu_pusage_colored=$(get_gpu_color "$gpu_pusage")
		gpu_view="${gpu_view//'#{gpu.pused}'/$(printf "%.1f%%" "$gpu_pusage")}"
		gpu_view="${gpu_view//'#{gpu.color}'/$(echo "$gpu_pusage_colored" | awk '{print $1}')}"
		gpu_view="${gpu_view//'#{gpu.color2}'/$(echo "$gpu_pusage_colored" | awk '{ print $2 }')}"
		gpu_view="${gpu_view//'#{gpu.color3}'/$(echo "$gpu_pusage_colored" | awk '{ print $3 }')}"
		if [ -n "$gpu_gb_usage" ]; then
			gpu_view="${gpu_view//'#{gpu.gbused}'/$(echo "$gpu_gb_usage"GB)}"
		else
			gpu_view='GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default]'
		fi
		echo "$gpu_view"
	fi
}

function main() {
	get_gpu_vendor
	print_gpu_pusage
}

main
