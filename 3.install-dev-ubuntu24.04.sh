#!/bin/bash
# db

cat > ~/.ssh/config <<EOF
Host github.com
  HostName ssh.github.com
  User git
  ProxyCommand connect -S 127.0.0.1:7897 %h %p
EOF

# xremap

# gnome tweak and `extensions` app
sudo apt install -y gnome-tweaks gnome-shell-extensions chrome-gnome-shell
cargo install xremap --features gnome   # GNOME Wayland
sudo gpasswd -a `whoami` input
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
cp ./xremap.config.yml ~/.config/xremap.yml
nohup sudo $HOME/.cargo/bin/xremap $HOME/.config/xremap.yml &