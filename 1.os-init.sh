#!/bin/zsh
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

# 加载所有变量 zshrc -> .bash_profile -> .dev_rc
\cp ./bashrc.sh ~/.dev_rc
cat >> ~/.bash_profile <<EOF
test -f ~/.dev_rc && source ~/.dev_rc
EOF

sed "/bash_profile/d" -i ~/.zshrc

cat >> ~/.zshrc <<EOF
test -f ~/.bash_profile && source ~/.bash_profile
EOF

. ~/.zshrc
