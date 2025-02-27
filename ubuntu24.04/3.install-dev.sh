#!/bin/bash
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

function configure_git() {
  # git SSH代理
  cat >~/.ssh/config <<EOF
Host github.com
  HostName ssh.github.com
  User git
  ProxyCommand connect -S 127.0.0.1:7897 %h %p
EOF

  git config --global core.quotepath false
  git config --global user.name "tb"
  git config --global user.email "travisbikkle@proton.me"

  cat >>~/.gitconfig <<EOF
[url "ssh://git@github.com/"]
  insteadOf = https://github.com/
EOF

}

# 阿里云镜像服务个人控制台 
# https://cr.console.aliyun.com/cn-hangzhou/instance/dashboard
# username=snzhaoyua
# docker login --username="$username" registry.cn-hangzhou.aliyuncs.com
# 拉取
# docker pull registry.cn-hangzhou.aliyuncs.com/eliteunited/ubuntu:24.04 && docker tag registry.cn-hangzhou.aliyuncs.com/eliteunited/ubuntu:24.04 ubuntu:24.04
# 推送
# https://github.com/dev-easily/docker-auto-mirror
function install_docker() {
  repo_arch=$(uname -m)
  if [ "$repo_arch" == "x86_64" ]; then
    repo_arch="amd64"
  else
    repo_arch="arm64" # not tested
  fi
  sudo apt-get update
  sudo apt-get remove docker.io containerd runc
  sudo apt-get install curl software-properties-common -y
  sudo curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=$repo_arch] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" -y
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  docker --version
}

function main() {
  configure_git
  install_docker
  sudo apt install mysql-client-core-8.0 -y
}

main
