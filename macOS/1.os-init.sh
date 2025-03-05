#!/bin/zsh
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

### brew
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"

git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
/bin/bash brew-install/install.sh

brew update

### bash
brew install bash

### git
touch ~/.gitignore_global
cat > ~/.gitignore_global <<EOF
.DS_Store
EOF
git config --global core.excludesfile ~/.gitignore_global
git config --global core.quotepath false

# git 的ssh代理在install-dev*.sh中
cat >> ~/.gitconfig <<EOF
[url "ssh://git@github.com/"]
  insteadOf = https://github.com/
EOF

# git 的https代理

# 加载所有变量 zshrc -> .bash_profile -> .dev_rc
\cp ./bashrc.sh ~/.dev_rc
sed "/dev_rc/d" -i ~/.bashrc
cat >> ~/.bashrc <<EOF
test -f ~/.dev_rc && source ~/.dev_rc
EOF

sed "/bashrc/d" -i ~/.bash_profile
cat >> ~/.bash_profile <<EOF
test -f ~/.bashrc && source ~/.bashrc
EOF

sed "/bash_profile/d" -i ~/.zshrc

cat >> ~/.zshrc <<EOF
test -f ~/.dev_rc && source ~/.dev_rc
EOF

. ~/.zshrc
