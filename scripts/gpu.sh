#!/usr/bin/env bash

print_gpu_usage() {
    function getGPUUsage() {
        gpuVendor=$(glxinfo | rg "OpenGL vendor string:" | awk '{print $4}')
        case "$gpuVendor" in
            AMD) gpuUsage=$(cat /sys/class/drm/card0/device/gpu_busy_percent)
            ;;
            NVIDIA) gpuUsage=($(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}'))
            ;;
            # *) echo default
            # ;;
        esac
    }
    getGPUUsage
    gpuUsage=("${gpuUsage[@]/%/%}")

    function join_by { local IFS="$1"; shift; echo "$*"; }
    gpuUsage=`join_by " " ${gpuUsage[@]}`
    if [ -z "$gpuUsage" ]; then
        echo "-"
    else
        echo "GPU: $gpuUsage"
    fi
}
main() {
    print_gpu_usage
}
main
