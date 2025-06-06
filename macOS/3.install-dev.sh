#!/bin/bash
# git ssh proxy clash meta
cat > ~/.ssh/config <<EOF
Host github.com
HostName github.com
User git
ProxyCommand nc -v -x 127.0.0.1:7890 %h %p
EOF

# db
# brew install mysql@8.0
# brew install redis@6.2

# tools
brew install apifox
brew install figma

function install_wezterm {
  brew install --cask wezterm
  brew install --cask font-hack-nerd-font
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
function install_nvim() {
  brew install neovim
  mkdir -p ~/.config/nvim
  git clone --depth=1 git@github.com:travisbikkle/nvim-config.git ~/.config/nvim
  # brew install --cask font-hack-nerd-font # 可以解压本仓库的字体
  brew install ripgrep
  /opt/homebrew/bin/python3 -m venv ~/.config/nvim_python
  source ~/.config/nvim_python/bin/activate
  pip3 install -U pynvim
  pip3 install 'python-lsp-server[all]' pylsp-mypy python-lsp-isort python-lsp-black
  npm install -g vim-language-server
  brew install universal-ctags
  rustup component add rust-analyzer
  #rustup +nightly component add rust-analyzer
}
install_nvim

# emacs
function install_emacs() {
  rustup component add rust-analyzer
  #rustup +nightly component add rust-analyzer
  brew tap d12frosted/emacs-plus
  brew install ripgrep coreutils fd emacs-plus libvterm
  ln -s /usr/local/opt/emacs-plus/Emacs.app /Applications/Emacs.app
  git clone --depth=1 git@github.com:doomemacs/doomemacs.git ~/.emacs.d
  DOOMGITCONFIG=~/.gitconfig ~/.emacs.d/bin/doom install
  rm -rf ~/.doom.d/
  git clone git@github.com:travisbikkle/.doom.d.git ~/.doom.d
  ~/.emacs.d/bin/doom sync
  # 字体，语法
  # M-x nerd-icons-install-fonts
  # M-x treesit-install-language-grammar typescript
  # M-x treesit-install-language-grammar rust
  # 启动服务端
}
install_emacs

# git-quick-stats
brew install coreutils
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
brew install git-quick-stats
