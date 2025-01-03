## 把这个放到 home 目录并且让 bash_profile 引用

alias ll="ls -al"

# region homebrew
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
# endregion

# region rust
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

test -f ~/.cargo/env && . ~/.cargo/env
# endregion rust

# region pnpm
export PNPM_HOME="/Users/yu/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# endregion

# region nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
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

# python3
alias python=`which python3`