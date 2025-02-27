#!/bin/bash
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

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

#sudo dnf groupinstall "Development Tools" #(dnf4) 
sudo dnf install @development-tools #(dnf5)

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/yu/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/yu/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
