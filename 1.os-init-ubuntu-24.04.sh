#!/bin/bash

# if not root
if [ $(id -u) -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# 软件仓库，系统时区，系统语言
echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list && \
echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
echo "deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
apt-get update && \
apt-get install wget locales libfreetype6 fontconfig openssh-server -y && \
fc-cache --force && \
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

systemctl start ssh

# 安装基础软件
apt install build-essential python-is-python3 curl connect-proxy -y

git config --global core.quotepath false
cat >> ~/.gitconfig <<EOF
[url "ssh://git@github.com/"]
  insteadOf = https://github.com/
EOF

# 加载所有变量 zshrc -> .bash_profile -> .dev_rc
\cp ./bashrc.sh ~/.dev_rc
cat >> ~/.bash_profile <<EOF
test -f ~/.dev_rc && source ~/.dev_rc
EOF
