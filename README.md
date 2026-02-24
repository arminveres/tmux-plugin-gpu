# tmux-plugin-gpu

tmux plugin showing GPU usage

![image](https://user-images.githubusercontent.com/45210978/214135521-e0a729af-9aed-4fac-81c5-79f189b74374.png)

## Requirements

At the moment `glxinfo` and `lspci` are required for determining the vendor.

```bash
# NixOS
nix shell "nixpkgs#mesa-demos"
nix shell "nixpkgs#pciutils"
# Fedora
dnf install glx-utils
```

For NVIDIA monitoring CUDA toolkit must be installed (the plugin internally calls `nvidia-smi`)

```bash
# NixOS: tbd
# Fedora
dnf install xorg-x11-drv-nvidia-cuda
```

For AMD install `radeontop`.

```bash
nix shell "nixpkgs#radeontop"
dnf install radeontop
```

## Installation

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin 'arminveres/tmux-plugin-gpu'
```

Hit `prefix + I` to fetch the plugin and source it.

If format strings are added to `status-right`, they should now be visible.

## Usage

In order to see GPU usage via this tmux plugin, add the following command to your `.tmux.conf` file:

```
#{gpu}
```

By default the usage in percentage and in vram are configured with the following setting, which also sums up the 2 options for now.

```tmux
set -g @sysstat_gpu_view_tmpl 'GPU:#[fg=#{gpu.color}]#{gpu.pused}#[default] #{gpu.gbused}'
# Set extra opts for radeontop, e.g., for multi GPU setups.
set -g @sysstat_gpu_opts "--path /dev/dri/renderD128"
```

## TODO

- [ ] add Intel iGPU support

## Acknowledgements

I used https://github.com/danijoo/tmux-plugin-simple-gpu as a base/fork for this
and he in turn used https://github.com/pwittchen/tmux-plugin-ram as a base.

In addition I also used helpers from [samoshkin's sysstat plugin](https://github.com/samoshkin/tmux-plugin-sysstat),
which greatly eased the dealings with tmux!
