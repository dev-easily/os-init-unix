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
  go env -w GO111MODULE=on
  go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
}
install_golang
# endregion
