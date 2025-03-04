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

function install_nvim() {
  curl -LO https://gh-proxy.com/github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  sudo apt install ripgrep python3.12-venv universal-ctags xclip -y
  mkdir -p ~/.config/nvim
  git clone --depth=1 git@github.com:travisbikkle/nvim-config.git ~/.config/nvim
  /usr/bin/python -m venv ~/.config/nvim_python/
  source ~/.config/nvim_python/bin/activate
  pip install -U pynvim
  pip install 'python-lsp-server[all]' pylsp-mypy python-lsp-isort python-lsp-black
  npm install -g vim-language-server
  cargo component add rust-analyzer
}

function install_doom_emacs() {
  sudo apt install ripgrep emacs fd-find xclip xdotool xprop xwininfo -y
  git clone --depth=1 git@github.com:travisbikkle/doomemacs.git ~/.emacs.d
  DOOMGITCONFIG=~/.gitconfig ~/.emacs.d/bin/doom install
  ~/.emacs.d/bin/doom doctor
  rm -rf ~/.doom.d/
  git clone git@github.com:travisbikkle/.doom.d.git ~/
  ~/.emacs.d/bin/doom sync
  # M-x nerd-icons-install-fonts
  # M-x treesit-install-language-grammar typescript
  # M-x treesit-install-language-grammar rust
  sed "/emacs/d" -i ~/.bash_profile
  echo "/usr/local/bin/emacs --daemon" >> ~/.bash_profile
}

function main() {
  configure_git
  install_docker
  sudo apt install mysql-client-core-8.0 -y
  install_nvim
  install_doom_emacs
  sudo snap install vscode
}

main
