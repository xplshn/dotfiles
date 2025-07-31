# System options:
export ENV="$HOME/.shrc"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/.$(id -u)-runtime-dir}"
[ -d "$XDG_RUNTIME_DIR" ] || { mkdir -p "$XDG_RUNTIME_DIR" && chmod 0700 "$XDG_RUNTIME_DIR"; }
export POSIXLY_CORRECT=1
export XDG_DATA_DIRS="$HOME/.local/share:/usr/local/share:/usr/share:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share"
export XDG_CONFIG_DIRS="$HOME/.config"
export PATH="$PATH:$HOME/.local/bin:$HOME/Applications:$HOME/.local/share/flatpak/exports/bin"

# User prefferences:
export MINPS1="1" # Whether to show your "$HOSTNAME" in your "$PS1", this var is used by .shrc
export LOCATION="Santiago_del_Estero" # The location used by WTTR, this var is referenced by .shrc
export COOLHOME="]" # The indicator used with hpwd to indicate that the dir you in "$HOME"
export COOLHOME_DEPTH="$COOLHOME~" # The indicator used with hpwd to indicate that the dir you are in is at "$HOME" or a subdirectory of "$HOME"
export COOLSPINNER="|/-\\" # For a BSD styled spinner animation in scripst that use /etc/skel/.local/bin/.std.h.sh
export COOLSPINNER_COLOR='\033[32m' # Green spinner/loading animation in scripst that use /etc/skel/.local/bin/.std.h.sh
export A_SYHX_COLOR_SCHEME="xcode-dark" # Color scheme to be used by CCAT
#Other relevant variables include: $EDITOR, $BROWSER

# pfetch prefferences
export PF_INFO="ascii title os host kernel uptime shell term editor pkgs memory palette"
export PF_SEP="@→"
export PF_DISABLED_PACKAGE_MANAGERS="flatpak cargo"

# Go options:
export CGO_ENABLED=0
export GOFLAGS="-ldflags=-static-pie -ldflags=-s -ldflags=-w"
export GO_LDFLAGS="-buildmode=static-pie -s -w"
export CGO_CFLAGS="-O2 -pipe -static -static-pie -w -Wno-error"
#export GOEXPERIMENT="greenteagc"
#export GOROOT="$(echo /usr/lib/go-*)"
export GOCACHE="$HOME/.cache/go"
export GOBIN="$HOME/.local/bin"
export GOPATH="$HOME/.cache/go"
# Rust options:
#export RUSTFLAGS="-C link-arg=-s"
export RUSTUP_HOME="$HOME/.cache/rs_rustup"
export CARGO_HOME="$HOME/.cache/rs_cargo"
# C options:
#export CC="clang"
#export CXX="clang++"
#export LD="mold"
#export CFLAGS="-O2 -flto=auto -pipe -static -static-pie"
#export CPPFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}"
#export LDFLAGS="-static -static-pie -Wl,--Bstatic,--build-id=none,--no-dynamic-linker,--no-fatal-warnings,--static,--stats,--strip-debug,--strip-all,-z,noexecstack,-z,now,-z,pack-relative-relocs,-z,relro"

# Nature options
export NATURE_ROOT="/opt/toolchains/nature"

# Wine
export WINEPREFIX="$HOME/.local/share/wine"

# Runimage ALSA support
#export RIM_BIND="/etc/asound.conf:/etc/asound.conf,/etc/alsa:/etc/alsa,/usr/share/alsa:/usr/share/alsa, /usr/share/alsa-card-profile:/usr/share/alsa-card-profile"

# AppBundles & "uruntime"
export DWARFS_CACHESIZE="256M"

# Graphical options:
export XCURSOR_THEME=plan9cursors
export XCURSOR_SIZE=24
export XCURSOR_PATH="${XCURSOR_PATH}:~/.local/share/icons"
export QT_QPA_PLATFORM="wayland;xcb"
export SDL_VIDEODRIVER="wayland"
export PROTON_ENABLE_WAYLAND=1
export SDL_AUDIODRIVER="pipewire"

# Always use intel iGPU
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/intel_icd.x86_64.json:usr/share/vulkan/icd.d/intel_icd.i686.json"
