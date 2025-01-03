#!/bin/bash
# db
brew install mysql@8.0
brew install redis@6.2

# tools
brew install apifox
brew install figma

function install_wezterm {
  brew install --cask wezterm
  brew tap homebrew/cask-fonts
  brew install font-jetbrains-mono-nerd-font


  mkdir -p $HOME/.config/wezterm
  git clone git@github.com:dev-easily/wezterm-config.git ~/.config/wezterm
}
install_wezterm

# xcode
mkdir -p ~/dev
cat > ~/dev/open_terminal.sh <<EOF
#!/bin/bash
open -a Terminal \$(pwd)
EOF
chmod +x ~/dev/open_terminal.sh

brew install --cask gimp
brew install --cask incscape
## kdenlive

# git ssh proxy clash meta
cat > ~/.ssh/config <<EOF
Host github.com
HostName github.com
User git
ProxyCommand nc -v -x 127.0.0.1:7891 %h %p
EOF

# git-quick-stats
brew install coreutils
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
brew install git-quick-stats
