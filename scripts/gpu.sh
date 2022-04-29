#!/usr/bin/env bash

print_gpu_usage() {
    gpuVendor=$(glxinfo | grep "OpenGL vendor string:" | awk '{print $4}')
    case "$gpuVendor" in
        AMD)
            gpuUsage=$(radeontop -c -d - -l 1 | grep gpu | awk '{print $5}' | sed 's/%,//')
            # gpuUsage=$(cat /sys/class/drm/card0/device/gpu_busy_percent) # use this for independent gpu usage
        ;;
        NVIDIA)
            gpuUsage=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
        ;;
        # INTEL)
        # ;;
        Mesa/X.org) echo SSH
        ;;
    esac
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
