#!/bin/zsh
# 编程语言SDK安装模块

# 导入通用函数
source "$(dirname "$0")/common.sh"

# Rust安装
install_rust() {
    if command -v rustc >/dev/null 2>&1; then
        log_info "Rust 已安装 ($(rustc --version))"
        return 0
    fi
    
    if should_skip_installation "cargo"; then
        log_info "跳过 Rust 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Rust..."
    
    # 设置中国镜像
    export RUSTUP_DIST_SERVER=https://rsproxy.cn
    export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
    
    # 如果设置了外部开发目录，确保.cargo目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "cargo"
    fi
    
    # 下载并运行安装脚本
    local script_dir="$(dirname "$0")/.."
    if [ -f "$script_dir/rustup-init.sh" ]; then
        sh "$script_dir/rustup-init.sh" -y --default-toolchain stable
    else
        curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
    fi
    
    # 配置cargo镜像
    ensure_dev_dir ~/.cargo "cargo"
    cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"

[registries.ustc]
index = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"

[net]
git-fetch-with-cli = true
EOF
    
    # 重新加载环境
    source ~/.cargo/env
    
    # 安装常用工具
    log_info "安装 Rust 常用工具..."
    cargo install cargo-update cargo-tree cargo-audit
    
    # 添加常用target
    rustup target add wasm32-unknown-unknown
    
    log_success "Rust 安装完成 ($(rustc --version))"
}

# Node.js安装
install_nodejs() {
    if command -v node >/dev/null 2>&1; then
        log_info "Node.js 已安装 ($(node --version))"
        return 0
    fi
    
    if should_skip_installation "nvm"; then
        log_info "跳过 Node.js 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Node.js..."
    
    # 如果设置了外部开发目录，确保.nvm目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "nvm"
    else
        ensure_dir ~/.nvm
    fi
    
    if ! command -v nvm >/dev/null 2>&1; then
        # 使用Homebrew安装nvm
        brew install nvm
        
        # 加载nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
    fi
    
    # 设置Node.js镜像
    export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/
    
    # 安装最新LTS版本
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
    
    # 配置npm镜像
    npm config set registry https://registry.npmmirror.com
    npm config set disturl https://npmmirror.com/dist
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/
    
    # 安装全局包管理器
    npm install -g pnpm yarn
    
    # 配置pnpm
    pnpm config set registry https://registry.npmmirror.com
    pnpm setup
    
    # 配置yarn
    yarn config set registry https://registry.npmmirror.com
    
    log_success "Node.js 安装完成 ($(node --version))"
}

# Python安装
install_python() {
    if command -v pyenv >/dev/null 2>&1; then
        log_info "Python (pyenv) 已安装"
        pyenv versions
        return 0
    fi
    
    if should_skip_installation "pyenv"; then
        log_info "跳过 Python 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Python..."
    
    # 如果设置了外部开发目录，确保相关目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "pyenv"
        create_dev_link "pip"
    fi
    
    # 安装pyenv
    brew install pyenv pyenv-virtualenv
    
    # 重新加载环境
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    # 设置Python编译环境
    export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
    export PYTHON_BUILD_MIRROR_URL="https://registry.npmmirror.com/-/binary/python"
    
    # 安装Python版本
    local python_versions=("3.11" "3.12")
    for version in "${python_versions[@]}"; do
        if ! pyenv versions | grep -q "$version"; then
            log_info "安装 Python $version..."
            pyenv install "$version"
        fi
    done
    
    # 设置全局Python版本
    pyenv global 3.12
    
    # 配置pip镜像
    ensure_dev_dir ~/.pip "pip"
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com
timeout = 120
EOF
    
    # 升级pip并安装常用包
    pip install --upgrade pip setuptools wheel
    pip install virtualenv pipenv poetry
    
    log_success "Python 安装完成"
    pyenv versions
}

# Go安装
install_golang() {
    if command -v go >/dev/null 2>&1; then
        log_info "Go 已安装 ($(go version))"
        return 0
    fi
    
    if should_skip_installation "go"; then
        log_info "跳过 Go 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Go..."
    
    # 如果设置了外部开发目录，确保go目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "go"
    fi
    
    # 使用Homebrew安装Go
    brew install go
    
    # 重新加载环境
    export GOPATH=$HOME/.go
    export GOROOT=$(brew --prefix go)/libexec
    export PATH=$PATH:$GOPATH/bin:$GOROOT/bin
    
    # 创建Go工作目录
    ensure_dir "$GOPATH/src"
    ensure_dir "$GOPATH/bin"
    ensure_dir "$GOPATH/pkg"
    
    # 配置Go代理
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://goproxy.cn,direct
    go env -w GOSUMDB=sum.golang.google.cn
    go env -w GOPRIVATE=""
    
    # 安装常用工具
    log_info "安装 Go 常用工具..."
    go install golang.org/x/tools/cmd/godoc@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install github.com/go-delve/delve/cmd/dlv@latest
    go install honnef.co/go/tools/cmd/staticcheck@latest
    
    log_success "Go 安装完成 ($(go version))"
}

# Java安装
install_java() {
    if command -v java >/dev/null 2>&1; then
        log_info "Java 已安装 ($(java -version 2>&1 | head -n 1))"
        return 0
    fi
    
    if should_skip_installation "m2"; then
        log_info "跳过 Java 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Java..."
    
    # 如果设置了外部开发目录，确保.m2目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "m2"
    fi
    
    # 安装多个Java版本
    local java_versions=("openjdk@11" "openjdk@17" "openjdk@21")
    
    for version in "${java_versions[@]}"; do
        if ! brew list "$version" &>/dev/null; then
            log_info "安装 $version..."
            brew install "$version"
        fi
    done
    
    # 配置Maven
    if ! command -v mvn >/dev/null 2>&1; then
        brew install maven
    fi
    
    ensure_dev_dir ~/.m2 "m2"
    local root_dir="$(cd "$(dirname "$0")"/../../ && pwd)"
    if [ -f "$root_dir/config/mvn_settings.xml" ]; then
        cp "$root_dir/config/mvn_settings.xml" ~/.m2/settings.xml
        log_info "已配置Maven镜像"
    fi
    
    # 安装Gradle
    if ! command -v gradle >/dev/null 2>&1; then
        brew install gradle
    fi
    
    log_success "Java 安装完成"
}

# PHP安装
install_php() {
    if command -v php >/dev/null 2>&1; then
        log_info "PHP 已安装 ($(php --version | head -n 1))"
        return 0
    fi
    
    log_info "安装 PHP..."
    
    # 安装PHP和常用扩展
    brew install php composer
    
    # 配置Composer镜像
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
    
    log_success "PHP 安装完成 ($(php --version | head -n 1))"
}

# Ruby安装
install_ruby() {
    if command -v rbenv >/dev/null 2>&1; then
        log_info "Ruby (rbenv) 已安装"
        rbenv versions
        return 0
    fi
    
    if should_skip_installation "rbenv"; then
        log_info "跳过 Ruby 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Ruby..."
    
    # 如果设置了外部开发目录，确保.rbenv目录软链接存在
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "rbenv"
    fi
    
    # 安装rbenv
    brew install rbenv ruby-build
    
    # 重新加载环境
    eval "$(rbenv init -)"
    
    # 安装最新稳定版Ruby
    local latest_ruby=$(rbenv install -l | grep -v - | tail -1 | tr -d ' ')
    rbenv install "$latest_ruby"
    rbenv global "$latest_ruby"
    
    # 配置gem镜像
    gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/
    
    # 安装常用gem
    gem install bundler rails
    
    log_success "Ruby 安装完成 ($(ruby --version))"
}

# Flutter安装
install_flutter() {
    if command -v flutter >/dev/null 2>&1; then
        log_info "Flutter 已安装 ($(flutter --version | head -n 1))"
        return 0
    fi
    
    if should_skip_installation "flutter"; then
        log_info "跳过 Flutter 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "安装 Flutter..."
    
    # 设置Flutter镜像
    export PUB_HOSTED_URL="https://pub.flutter-io.cn"
    export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
    
    # 确定Flutter安装路径 - 使用外部开发目录或本地目录
    local flutter_path
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        flutter_path="$DEV_EXTERNAL_PATH/flutter"
        # 创建软链接到 ~/.dev/flutter
        create_dev_link "flutter"
    else
        ensure_dir ~/.dev
        flutter_path="$HOME/.dev/flutter"
    fi
    
    # 获取Flutter版本信息
    local flutter_version="3.29.2"
    local arch=$(uname -m)
    local package_arch=""
    
    if [[ $arch == "arm64" ]]; then
        package_arch="_arm64"
    fi
    
    # 下载Flutter
    local flutter_url="https://storage.flutter-io.cn/flutter_infra_release/releases/stable/macos/flutter_macos${package_arch}_${flutter_version}-stable.zip"
    local flutter_zip="/tmp/flutter-latest.zip"
    
    if safe_download "$flutter_url" "$flutter_zip"; then
        local install_dir="$(dirname "$flutter_path")"
        ensure_dir "$install_dir"
        
        cd "$install_dir"
        unzip -q "$flutter_zip"
        rm "$flutter_zip"
        
        export PATH="$HOME/.dev/flutter/bin:$PATH"
        
        # 安装CocoaPods (iOS开发需要)
        if ! command -v pod >/dev/null 2>&1; then
            brew install cocoapods
        fi
        
        # 配置Flutter
        flutter config --no-analytics
        flutter --disable-analytics
        
        # 运行flutter doctor
        log_info "运行 Flutter Doctor..."
        flutter doctor
        
        log_success "Flutter 安装完成 ($(flutter --version | head -n 1))"
    else
        log_error "Flutter 下载失败"
        return 1
    fi
}

# 显示语言安装菜单
show_language_menu() {
    echo -e "\n${YELLOW}选择要安装的编程语言:${NC}"
    echo "1. Rust"
    echo "2. Node.js"
    echo "3. Python"
    echo "4. Go"
    echo "5. Java"
    echo "6. PHP"
    echo "7. Ruby"
    echo "8. Flutter/Dart"
    echo "9. 全部安装"
    echo "0. 返回主菜单"
    echo -n -e "\n${BLUE}请选择 [0-9]: ${NC}"
}

# 主函数
main() {
    log_info "编程语言SDK安装模块"
    
    while true; do
        show_language_menu
        read -r choice
        
        case $choice in
            1) install_rust ;;
            2) install_nodejs ;;
            3) install_python ;;
            4) install_golang ;;
            5) install_java ;;
            6) install_php ;;
            7) install_ruby ;;
            8) install_flutter ;;
            9)
                log_info "安装所有编程语言..."
                install_rust
                install_nodejs
                install_python
                install_golang
                install_java
                install_php
                install_ruby
                if confirm_action "是否安装 Flutter"; then
                    install_flutter
                fi
                ;;
            0) break ;;
            *) log_error "无效选项" ;;
        esac
        
        wait_for_key
    done
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi