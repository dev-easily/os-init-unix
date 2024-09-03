#!/bin/bash

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

  cargo install crm
}
install_rust
## endregion rust

## region node&electron
function install_node() {
  brew install npm pnpm
  pnpm setup
  npm config set registry https://registry.npmmirror.com
  curl -o- https://cdn.jsdelivr.net/gh/nvm-sh/nvm@v0.40.0/install.sh | bash
  export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
  nvm install 20
  node -v
  npm -v
}
install_node
## endregion

## region python
function install_python() {
  brew install python@3.12
  pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
  pip3 config set global.index https://mirrors.aliyun.com/pypi
  pip3 config set global.trusted-host mirrors.aliyun.com
  pip3 install setuptools
}
install_python
## endregion

## region openjdk17
function install_jdk() {
  brew install openjdk@17
  mkdir ~/.m2
  \cp ./mvn_settings.xml ~/.m2/settings.xml
}
install_jdk
## endregion

# region golang
function install_golang() {
  brew install go@1.23
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
  export PUB_HOSTED_URL="https://pub.flutter-io.cn"
  export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
  #brew install --cask flutter
  #brew install ruby
  #export PATH=$PATH:/usr/local/opt/ruby/bin
  #sudo gem install drb -v 2.0.6
  #sudo gem install cocoapods
  brew install cocoapods
  #brew link --overwrite cocoapods
  mkdir ~/dev
  curl https://storage.flutter-io.cn/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.1-stable.zip -o ~/dev/flutter_macos_3.24.1-stable.zip
  unzip ~/dev/flutter_macos_3.24.1-stable.zip -d ~/dev/
  rm -rf ~/dev/flutter_macos_3.24.1-stable.zip
  ~/dev/flutter/bin/flutter doctor
  ~/dev/flutter/bin/flutter config --no-analytics
}
install_flutter
# endregion

# region java
function install_java() {
  # need sudo
  brew install oracle-jdk@17 
}
install_java
# endregion