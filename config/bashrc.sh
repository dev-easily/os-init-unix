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
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew-bottles/api"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"

eval $(/opt/homebrew/bin/brew shellenv) #ckbrew

# endregion

# region rust
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

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
export NVM_INSTALL_DIR="/opt/homebrew/opt/nvm"
[ -s "$NVM_INSTALL_DIR/nvm.sh" ] && \. "$NVM_INSTALL_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_INSTALL_DIR/bash_completion" ] && \. "$NVM_INSTALL_DIR/bash_completion"  # This loads nvm bash_completion
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
# endregion

# region electron
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
export ELECTRON_CUSTOM_DIR=30.0.6
export ELECTRON_BUILDER_BINARIES_MIRROR=https://npmmirror.com/mirrors/electron-builder-binaries/
# endregion

# region openjdk17
export PATH=$PATH:/usr/local/opt/openjdk@17/bin
# endregion

# region ruby
export PATH=$PATH:/usr/local/opt/ruby/bin:$HOME/.gem/bin

# endregion

# region flutter
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PATH=$PATH:~/dev/flutter/bin:~/.pub-cache/bin
if [[ "$(uname)" == "Linux" ]];then
    export CHROME_EXECUTABLE="/opt/microsoft/msedge/msedge"
fi
## For compilers to find ruby you may need to set:
##   export LDFLAGS="-L/usr/local/opt/ruby/lib"
##   export CPPFLAGS="-I/usr/local/opt/ruby/include"
# endregion

# region golang
export PATH=$PATH:~/go/bin
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
        PS1="\[\033[32m\]$(parse_git_branch)\[\033[00m\] \[\e[33m\]\u@$(hostname -I|cut -d ' ' -f 1)\[\e[0m\]:\w $ "
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
export OLLAMA_MODELS=/Volumes/1T/LargeApplications/AIModels/
## ollama pull nomic-embed-text

## pyenv download mirror
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_BUILD_MIRROR_URL="https://registry.npmmirror.com/-/binary/python"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if is_zsh;then
  eval "$(pyenv init - zsh)"
elif is_bash;then
  eval "$(pyenv init - bash)"
fi