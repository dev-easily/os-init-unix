#!/bin/bash
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

must_run_as_non_root

# 将桌面用户添加sudo
sudo usermod -aG sudo $USER

# 软件仓库，系统时区，系统语言
function init_os() {
  echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
  echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
  echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
  echo "deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get install curl git sudo vim wget locales libfreetype6 fontconfig ca-certificates jq openssh-server -y && \
  fc-cache --force && \
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
}
sudo bash -c 'init_os'

# ssh开启
sudo systemctl start ssh

# 安装基础软件
sudo apt install build-essential python-is-python3 curl connect-proxy -y

# 加载所有变量 zshrc -> .bash_profile -> .dev_rc
> ~/.bash_profile
\cp $ROOT_DIR/config/bashrc.sh ~/.dev_rc
sed "/dev_rc/d" -i ~/.bashrc
sed "/bashrc/d" -i ~/.bash_profile

cat >> ~/.bashrc <<EOF
test -f ~/.dev_rc && source ~/.dev_rc
EOF
cat >> ~/.bash_profile <<EOF
test -f ~/.bashrc && source ~/.bashrc
EOF
