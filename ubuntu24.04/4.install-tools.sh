# gnome tweak and `extensions` app
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

sudo apt install -y gnome-tweaks gnome-shell-extensions chrome-gnome-shell gnome-shell-extension-manager
cargo install xremap --features gnome   # GNOME Wayland
sudo gpasswd -a `whoami` input
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
cp $ROOT_DIR/config/xremap.yml ~/.config/xremap.yml
sudo cp $ROOT_DIR/config/xremap.service /usr/lib/systemd/system/
sudo systemctl enable xremap.service
sudo systemctl start xremap.service

# onedrive
sudo add-apt-repository --remove ppa:jstaf/onedriver
sudo apt update
sudo apt install onedriver

# obsidian
sudo snap install obsidian

# 远程桌面
# 确保不要开启用户自动登录，可以修改 /etc/gdm3/custom.conf 文件，将 AutomaticLoginEnable 和 AutomaticLogin 两行注释
sed -i 's/AutomaticLoginEnable=true/AutomaticLoginEnable=false/g' /etc/gdm3/custom.conf
sed -i 's/AutomaticLogin=/#AutomaticLogin=/g' /etc/gdm3/custom.conf

# 为了解决每次重启后，远程桌面密码都变化的问题，需要用户设置空密码
# 搜索Passwords and Keys, 右键点击Login，选择修改密码，输入旧密码，然后设置空密码
