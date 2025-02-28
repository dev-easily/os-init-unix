#!/bin/bash
# git ssh proxy clash meta
cat > ~/.ssh/config <<EOF
Host github.com
HostName github.com
User git
ProxyCommand nc -v -x 127.0.0.1:7891 %h %p
EOF

# db
# brew install mysql@8.0
# brew install redis@6.2

# tools
brew install apifox
brew install figma

function install_wezterm {
  brew install --cask wezterm
  brew tap homebrew/cask-fonts
  brew install font-jetbrains-mono-nerd-font

  mkdir -p $HOME/.config/wezterm
  git clone --depth=1 git@github.com:dev-easily/wezterm-config.git ~/.config/wezterm
}
install_wezterm

# xcode
mkdir -p ~/dev
cat > ~/dev/open_terminal.sh <<EOF
#!/bin/bash
open -a Terminal \$(pwd)
EOF
chmod +x ~/dev/open_terminal.sh

# nvim, need python 3.12
brew install neovim
mkdir -p ~/.config/nvim
git clone --depth=1 git@github.com:travisbikkle/nvim-config.git ~/.config/nvim
brew install --cask font-hack-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
brew install ripgrep
/usr/local/bin/python3 -m venv ~/.config/nvim_python
source ~/.config/nvim_python/bin/activate
pip install -U pynvim
pip install 'python-lsp-server[all]' pylsp-mypy python-lsp-isort python-lsp-black
npm install -g vim-language-server
brew install universal-ctags

# node
brew install node

# 图像
brew install --cask gimp
brew install --cask incscape
## kdenlive

# git-quick-stats
brew install coreutils
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
brew install git-quick-stats
