#!/usr/bin/env bash

amd=`lspci | grep -i amd`
nvidia=`lspci | grep -i nvidia`
intel=`lspci | grep -i intel`

if [[ -n $amd ]]; then
    vendor="AMD"
elif [[ -n $nvidia ]]; then
    vendor="NVIDIA"
elif [[ -n $intel ]]; then
    # NOTE: even if there is a second GPU e.g intel, take the first dedicated one
    vendor="INTEL"
fi

print_gpu_usage() {
    case "$vendor" in
    AMD)
        gpuUsage=$(radeontop -c -d - -l 1 | grep gpu | awk '{print $5}' | sed 's/%,//')
        ;;
    NVIDIA)
        gpuUsage=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
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

    gpuUsage=("${gpuUsage[@]/%/%}")

    function join_by {
        local IFS="$1"
        shift
        echo "$*"
    }

    gpuUsage=$(join_by " " ${gpuUsage[@]})

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
