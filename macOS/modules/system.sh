#!/bin/zsh
# 系统初始化模块

# 导入通用函数
source "$(dirname "$0")/common.sh"

# Homebrew安装和配置
install_homebrew() {
    if should_skip_installation "homebrew"; then
        log_info "跳过 Homebrew 安装 (外部存储中已存在)"
        # 确保软链接存在
        if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
            create_dev_link "homebrew"
        fi
        # 设置环境变量
        eval $(/opt/homebrew/bin/brew shellenv)
        return 0
    fi
    
    if command_exists brew; then
        log_info "Homebrew 已安装，跳过"
        return 0
    fi
    
    log_info "安装 Homebrew..."
    
    # 如果设置了外部开发目录，先创建软链接
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "homebrew"
    fi
    
    # 设置中国镜像源
    export HOMEBREW_INSTALL_FROM_API=1
    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
    
    # 下载并安装
    git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
    /bin/bash brew-install/install.sh
    eval $(/opt/homebrew/bin/brew shellenv)
    rm -rf brew-install
    
    # 更新
    brew update
    
    log_success "Homebrew 安装完成"
}

# Git配置
configure_git() {
    log_info "配置 Git..."

    cat >~/.ssh/config <<EOF
Host github.com
  HostName ssh.github.com
  User git
  #ProxyCommand connect -S 127.0.0.1:7890 %h %p
EOF
    
    # 创建全局gitignore
    touch ~/.gitignore_global
    cat > ~/.gitignore_global <<EOF
.DS_Store
.vscode/
.idea/
*.log
node_modules/
.env
EOF
    
    git config --global core.excludesfile ~/.gitignore_global
    git config --global core.quotepath false
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    # 获取用户信息
    if [ -z "$(git config --global user.name)" ]; then
        echo -n -e "${BLUE}请输入Git用户名: ${NC}"
        read -r git_username
        git config --global user.name "$git_username"
    fi
    
    if [ -z "$(git config --global user.email)" ]; then
        echo -n -e "${BLUE}请输入Git邮箱: ${NC}"
        read -r git_email
        git config --global user.email "$git_email"
    fi
    
    # SSH配置
    if ! grep -q "github.com" ~/.gitconfig 2>/dev/null; then
        cat >> ~/.gitconfig <<EOF

[url "ssh://git@github.com/"]
  insteadOf = https://github.com/
EOF
    fi
    
    log_success "Git 配置完成"
}

# Shell环境配置
configure_shell() {
    log_info "配置 Shell 环境..."
    
    # 使用SCRIPT_DIR环境变量或者通过相对路径计算
    local root_dir
    if [ -n "${SCRIPT_DIR:-}" ]; then
        # SCRIPT_DIR指向macOS目录，需要向上一级到项目根目录
        root_dir="$(dirname "$SCRIPT_DIR")"
    else
        # 从modules目录向上两级到达项目根目录
        root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../ && pwd)"
    fi
    
    local bashrc_source="$root_dir/config/bashrc.sh"
    
    # 直接复制配置文件
    if [ -f "$bashrc_source" ]; then
        \cp "$bashrc_source" ~/.dev_rc
        log_success "已复制开发环境配置文件: $bashrc_source -> ~/.dev_rc"
    else
        log_error "配置文件不存在: $bashrc_source"
        log_error "当前工作目录: $(pwd)"
        log_error "脚本目录: $root_dir"
        return 1
    fi
    
    # 配置zshrc
    if ! grep -q "dev_rc" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "# 开发环境配置" >> ~/.zshrc
        echo "test -f ~/.dev_rc && source ~/.dev_rc" >> ~/.zshrc
        log_info "已配置 zshrc"
    fi
    
    # 配置bashrc
    if ! grep -q "dev_rc" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# 开发环境配置" >> ~/.bashrc
        echo "test -f ~/.dev_rc && source ~/.dev_rc" >> ~/.bashrc
        log_info "已配置 bashrc"
    fi
    
    # 配置bash_profile
    if ! grep -q "bashrc" ~/.bash_profile 2>/dev/null; then
        echo "" >> ~/.bash_profile
        echo "# 加载bashrc" >> ~/.bash_profile
        echo "test -f ~/.bashrc && source ~/.bashrc" >> ~/.bash_profile
        log_info "已配置 bash_profile"
    fi
    
    log_success "Shell 环境配置完成"
}

# 安装基础工具
install_basic_tools() {
    log_info "安装基础工具..."
    
    local tools=(
        "bash"
        "curl"
        "wget"
        "git"
        "vim"
        "tree"
        "htop"
        "jq"
        "unzip"
        "connect"
    )
    
    for tool in "${tools[@]}"; do
        if ! brew list "$tool" &>/dev/null; then
            log_info "安装 $tool..."
            brew install "$tool"
        fi
    done
    
    log_success "基础工具安装完成"
}

# 系统优化
optimize_system() {
    log_info "优化系统设置..."
    
    # 显示隐藏文件
    #defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # 显示文件扩展名
    #defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # 禁用自动纠正
    #defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # 加快窗口动画
    #defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    
    # 重启Finder使设置生效
    #killall Finder
    
    log_success "系统优化完成"
}

# 主函数
main() {
    log_info "开始系统初始化..."
    
    # 开发目录配置 (在安装其他组件之前)
    if confirm_action "是否配置开发目录管理 (推荐)"; then
        configure_dev_directory
    fi
    
    install_homebrew
    install_basic_tools
    configure_git
    configure_shell
    
    if confirm_action "是否进行系统优化"; then
        optimize_system
    fi
    
    log_success "系统初始化完成！请重启终端以使配置生效。"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi