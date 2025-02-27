# gnome tweak and `extensions` app
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

sudo apt install -y gnome-tweaks gnome-shell-extensions chrome-gnome-shell
cargo install xremap --features gnome   # GNOME Wayland
sudo gpasswd -a `whoami` input
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
cp ./xremap.config.yml ~/.config/xremap.yml
nohup sudo $HOME/.cargo/bin/xremap $HOME/.config/xremap.yml &
sudo cat > /etc/init.d/xremap <<EOF
#!/bin/bash
nohup $HOME/.cargo/bin/xremap $HOME/.config/xremap.yml &
EOF

# onedrive
sudo add-apt-repository --remove ppa:jstaf/onedriver
sudo apt update
sudo apt install onedriver