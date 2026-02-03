## 开发环境配置文件
## 把这个放到 home 目录并且让 bash_profile 引用

alias ll="ls -al"

function is_macos() {
  [[ "$(uname)" == "Darwin" ]]
}

function is_ubuntu() {
  [[ "$(uname)" == "Linux" ]] && cat /etc/os-release|grep Ubuntu &> /dev/null
}

function is_fedora() {
  [[ "$(uname)" == "Linux" ]] && lsb_release -a|grep Fedora &> /dev/null
}

function is_zsh() {
  [ -n "$ZSH_VERSION" ]
}

function is_bash() {
  [ -n "$BASH_VERSION" ]
}

# region homebrew
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"

if is_macos; then
  # 支持外置开发目录的Homebrew
  if [ -L "/opt/homebrew" ] && [ -d "/opt/homebrew" ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
  elif [ -d "/opt/homebrew" ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
  fi
fi
# endregion

# region rust
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# 支持外置开发目录的Cargo
test -f ~/.cargo/env && . ~/.cargo/env
# endregion rust

# region pnpm
export PNPM_HOME="${HOME}/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# endregion

# region nvm
export NVM_DIR="$HOME/.nvm"
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/

# 支持外置开发目录的NVM
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  \. "$HOME/.nvm/nvm.sh"
elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  \. "/opt/homebrew/opt/nvm/nvm.sh"
fi

# NVM bash completion
if [ -s "$HOME/.nvm/bash_completion" ]; then
  \. "$HOME/.nvm/bash_completion"
elif [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
  \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi
# endregion

# region electron
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
export ELECTRON_CUSTOM_DIR=30.0.6
export ELECTRON_BUILDER_BINARIES_MIRROR=https://npmmirror.com/mirrors/electron-builder-binaries/
# endregion

# region java
# 支持多版本Java
if command -v brew >/dev/null 2>&1; then
  export JAVA_HOME=$(brew --prefix openjdk@17 2>/dev/null || brew --prefix openjdk 2>/dev/null)
  [ -n "$JAVA_HOME" ] && export PATH="$JAVA_HOME/bin:$PATH"
fi
# endregion

# region ruby
# 支持外置开发目录的Ruby
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi
export PATH=$PATH:/usr/local/opt/ruby/bin:$HOME/.gem/bin
# endregion

# region flutter
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# 支持外置开发目录的Flutter
export PATH=$PATH:~/.dev/flutter/bin:~/.pub-cache/bin

if [[ "$(uname)" == "Linux" ]];then
    export CHROME_EXECUTABLE="/opt/microsoft/msedge/msedge"
fi
# endregion

# region golang
# 支持外置开发目录的Go
export GOPATH=$HOME/go
if command -v go >/dev/null 2>&1; then
  export GOROOT=$(go env GOROOT 2>/dev/null)
fi
export PATH=$PATH:$GOPATH/bin
export HUGO_MODULE_PROXY=https://goproxy.cn
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
# endregion

# region python
# 支持外置开发目录的Python
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_BUILD_MIRROR_URL="https://registry.npmmirror.com/-/binary/python"
export PYENV_ROOT="$HOME/.pyenv"

if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  if is_zsh; then
    eval "$(pyenv init - zsh)"
    eval "$(pyenv virtualenv-init -)"
  elif is_bash; then
    eval "$(pyenv init - bash)"
    eval "$(pyenv virtualenv-init -)"
  else
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  fi
fi
# endregion

# core-utils for git-quick-stats
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# code
export PATH=$PATH:'/Applications/Visual Studio Code.app/Contents/Resources/app/bin'

# doom emacs
export DOOMGITCONFIG="$HOME"/.gitconfig
# requires `emacs --daemon`
alias em="emacsclient"
alias et="emacsclient -t" # tui
alias ec="emacsclient -c" # gui

# nvim
function nvim() {
  if is_macos;then
    test -x /opt/homebrew/bin/nvim &> /dev/null && (
        test -f ~/.config/nvim_python/bin/activate && source ~/.config/nvim_python/bin/activate && /opt/homebrew/bin/nvim $@
    )
  else
    (test -f ~/.config/nvim_python/bin/activate && source ~/.config/nvim_python/bin/activate && /opt/nvim-linux-x86_64/bin/nvim $@)
  fi
}

# PS1
parse_git_branch() {
  git_branch=$(git branch 2> /dev/null|grep -- '*' || echo "not a git repo")
  echo "($git_branch)"
}

if is_zsh;then
    setopt PROMPT_SUBST
    precmd() {
      PS1="%F{green}$(parse_git_branch)%f %F{yellow}%n@%m%f:%c $ "
    }
elif is_bash;then
    set_bash_prompt() {
      if is_macos;then
        PS1="\[\033[32m\]$(parse_git_branch)\[\033[00m\] \[\e[33m\]\u@\h\[\e[0m\]:\w $ "
      elif is_ubuntu;then
        PS1="\[\033[32m\]$(parse_git_branch)\[\033[00m\] \[\e[33m\]\u@$(hostname -I|cut -d ' ' -f 1)\[\e[0m\]:\W $ "
      fi
    }
    PROMPT_COMMAND=set_bash_prompt
fi

## proxy
function proxy() {
  if [[ "$1" == "on" ]];then
    export HTTP_PROXY="http://127.0.0.1:7890"
    export HTTPS_PROXY="http://127.0.0.1:7890"
  else
    unset HTTP_PROXY
    unset HTTPS_PROXY
  fi
  echo "HTTP_PROXY: $HTTP_PROXY"
}

## Huggingface-hub
export HF_ENDPOINT="https://hf-mirror.com"
export OLLAMA_MIRROR=https://mirror.aliyun.com/ollama
if is_macos;then
  export OLLAMA_MODELS=/Volumes/1T/LargeApplications/AIModels/
else
  export OLLAMA_MODELS=${HOME}/AIModels/
fi

## uv
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"

# 开发工具别名
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
