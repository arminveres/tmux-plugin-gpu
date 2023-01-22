#!/usr/bin/env bash

function fcomp() {
	awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<n2) exit 0; exit 1}'
}

function get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value="$(tmux show-option -gqv "$option")"
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

function set_tmux_option() {
	local option="$1"
	local value="$2"
	tmux set-option -gq "$option" "$value"
}

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

vendor=''

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
	local gpu_view_tmpl=$(get_tmux_option "@sysstat_cpu_view_tmpl" 'GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default] #{gpu.gbused}')

	case "$vendor" in
	AMD)
		gpu_info=$(radeontop -c -d - -l 1 | grep gpu)
		gpu_pusage=$(echo "$gpu_info" | awk '{print $5}' | sed 's/%,/%/')
		gpu_mb_usage=$(echo "$gpu_info" | awk '{print $28}' | sed 's/.[0-9]*mb,//')
		gpu_gb_usage=$(printf %.2f "$gpu_mb_usage"e-3)
		;;
	NVIDIA)
		gpu_pusage=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
		;;
	INTEL)
		echo INTEL
		# TODO: add intel_top
		;;
	Mesa/X.org)
		echo SSH
		# NOTE: should be a non issue now
		;;
	esac

	if [ -z "$gpu_pusage" ]; then
		echo "-"
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
