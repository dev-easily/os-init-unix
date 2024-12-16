#!/bin/bash
. ~/.dev_rc

## region rust
function install_rust() {
  if command -v rustc; then
    return 0
  fi
  export RUSTUP_DIST_SERVER=https://rsproxy.cn
  export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -qy

  cat >>~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
EOF
  . ~/.dev_rc
  cargo install crm
}
install_rust
## endregion rust

## region node&electron
function install_node() {
  curl -o- https://cdn.jsdelivr.net/gh/nvm-sh/nvm@v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
  nvm install --lts
  npm config set registry https://registry.npmmirror.com
  npm i -g pnpm
  pnpm setup
  node -v
  npm -v
}
install_node
## endregion

## region python
function install_python() {
  if python --version|grep "Python 3";then
      return
  fi
  brew install python@3.12
  pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
  pip3 config set global.index https://mirrors.aliyun.com/pypi
  pip3 config set global.trusted-host mirrors.aliyun.com
  pip3 install setuptools
}
install_python
## endregion

# region golang
function install_golang() {
  if [[ "$(uname -n)" == "fedora" ]];then
      sudo dnf install golang
      return
  fi
  if command -v brew;then
      brew install go@1.23
  fi
  go env -w GO111MODULE=on && \
  go env -w GOPROXY=https://goproxy.io,direct && \
  go install golang.org/x/tools/cmd/godoc@latest
}
install_golang
# endregion

# region ruby gem
#sudo gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/
# endregion

# region flutter
function install_flutter() {
  if [[ "$(uname -n)" == "fedora" ]];then
      sudo dnf install clang cmake ninja-build gtk3-devel
      echo "please install flutter sdk with vscode flutter plugin"
      return
  fi

  if lsb_release -a|grep Ubuntu;then
      sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
      sudo apt-get install \
      clang cmake git \
      ninja-build pkg-config \
      libgtk-3-dev liblzma-dev \
      libstdc++-12-dev
      return
  fi


  export PUB_HOSTED_URL="https://pub.flutter-io.cn"
  export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
  #brew install --cask flutter
  #brew install ruby
  #export PATH=$PATH:/usr/local/opt/ruby/bin
  #sudo gem install drb -v 2.0.6
  #sudo gem install cocoapods 
  mkdir ~/dev

  if [[ "$(uname)" == "Darwin" ]];then
      brew install cocoapods           
      curl https://storage.flutter-io.cn/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip -o ~/dev/flutter-latest.zip
      unzip ~/dev/flutter-latest.zip -d ~/dev/
      rm -rf ~/dev/flutter-latest.zip
  fi

  if lsb_release -a|grep Ubuntu;then
      curl https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o ~/dev/flutter-latest.tar.xz
      curl https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o ~/dev/flutter-latest.tar.xz
      tar xvf ~/dev/flutter-latest.tar.xz -C ~/dev/
      rm -rf ~/dev/flutter-latest.tar.xz
  fi
  #brew link --overwrite cocoapods

  ~/dev/flutter/bin/flutter doctor  
  ~/dev/flutter/bin/flutter config --no-analytics
  ~/dev/flutter/bin/flutter --disable-analytics
}
install_flutter

function config_cocoa_pods {
  #https://mirrors.tuna.tsinghua.edu.cn/help/CocoaPods/
  cd ~/.cocoapods/repos
  pod repo remove master
  git clone https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git master
}
# config_cocoa_pods
# endregion

# region java
function install_java() {
  # need sudo
  brew install oracle-jdk@17 
}
install_java
# endregion