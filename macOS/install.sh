#!/bin/zsh
# macOS开发环境智能安装器
# 版本: 2.0.0
# 支持配置文件驱动、预设模式、交互式安装

set -e

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
CONFIG_FILE="$SCRIPT_DIR/config.json"

# 导入通用函数
source "$MODULES_DIR/common.sh"

# 导出配置文件路径供模块使用
export CONFIG_FILE

# 全局变量
INSTALLED_COMPONENTS=()
FAILED_COMPONENTS=()
INSTALL_LOG="$HOME/.config/macos_setup.log"

# 初始化日志
init_logging() {
    ensure_dir "$(dirname "$INSTALL_LOG")"
    echo "=== macOS开发环境安装 $(date) ===" >> "$INSTALL_LOG"
}

# 检查配置文件
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        exit 1
    fi
    
    if ! command_exists jq; then
        log_info "安装 jq 用于解析配置文件..."
        if command_exists brew; then
            brew install jq
        else
            log_error "需要先安装 Homebrew 或 jq"
            exit 1
        fi
    fi
}

# 读取配置
read_config() {
    local key="$1"
    jq -r "$key" "$CONFIG_FILE" 2>/dev/null || echo "null"
}

# 显示欢迎界面
show_welcome() {
    clear
    local version=$(read_config '.metadata.version')
    local description=$(read_config '.metadata.description')
    
    echo -e "${BLUE}"
    cat << EOF
╔══════════════════════════════════════════════════════════════╗
║                    macOS 开发环境安装器                        ║
║                      版本: $version                           ║
║                                                              ║
║  $description                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    show_system_info
}

# 系统检查
system_check() {
    log_info "执行系统检查..."
    
    # 检查macOS版本
    local required_version=$(read_config '.system.required_macos_version')
    local current_version=$(get_macos_version)
    
    log_info "当前macOS版本: $current_version"
    log_info "要求最低版本: $required_version"
    
    # 检查磁盘空间
    local required_space=$(read_config '.system.required_disk_space_gb')
    check_disk_space "$required_space"
    
    # 检查Xcode Command Line Tools
    if [ "$(read_config '.system.check_xcode_tools')" = "true" ]; then
        check_xcode_tools
    fi
    
    # 检查网络连接
    if [ "$(read_config '.system.check_network')" = "true" ]; then
        check_network
    fi
    
    log_success "系统检查通过"
}

# 显示预设模式菜单
show_preset_menu() {
    echo -e "\n${YELLOW}选择安装模式:${NC}"
    echo "1. 完整安装 - 安装所有可用组件"
    echo "2. 自定义安装 - 手动选择组件"
    echo "0. 退出"
    echo -n -e "\n${BLUE}请选择 [0-2]: ${NC}"
}

# 显示组件菜单
show_component_menu() {
    echo -e "\n${YELLOW}选择要安装的组件:${NC}"
    
    # 定义固定的显示顺序
    local display_order=("dev_tools" "languages" "system_init" "utility_tools")
    local i=1
    
    for package in "${display_order[@]}"; do
        local name=$(read_config ".packages.$package.name")
        local desc=$(read_config ".packages.$package.description")
        local required=$(read_config ".packages.$package.required")
        
        if [ "$required" = "true" ]; then
            echo "$i. $name - $desc ${GREEN}[必需]${NC}"
        else
            echo "$i. $name - $desc"
        fi
        ((i++))
    done
    
    echo -n -e "\n${BLUE}请选择组件 (多选用空格分隔): ${NC}"
}

# 安装预设模式
install_preset() {
    local preset_key="$1"
    local preset_name=$(read_config ".presets.$preset_key.name")
    
    log_info "安装预设: $preset_name"
    
    # 获取预设包含的组件
    local packages=$(read_config ".presets.$preset_key.packages[]?" | tr '\n' ' ')
    local languages=$(read_config ".presets.$preset_key.languages[]?" | tr '\n' ' ')
    local tools=$(read_config ".presets.$preset_key.tools[]?" | tr '\n' ' ')
    
    # 安装系统组件
    if [[ $packages == *"system_init"* ]]; then
        install_system_init
    fi
    
    # 安装语言
    if [[ $packages == *"languages"* ]] || [ -n "$languages" ]; then
        install_languages "$languages"
    fi
    
    # 安装开发工具
    if [[ $packages == *"dev_tools"* ]] || [ -n "$tools" ]; then
        install_dev_tools "$tools"
    fi
    
    # 安装实用工具
    if [[ $packages == *"utility_tools"* ]]; then
        install_utility_tools
    fi
}

# 安装系统初始化
install_system_init() {
    log_info "开始系统初始化..."
    
    # 设置镜像环境变量
    setup_mirrors
    
    # 运行系统模块
    if [ -f "$MODULES_DIR/system.sh" ]; then
        source "$MODULES_DIR/system.sh"
        if main; then
            INSTALLED_COMPONENTS+=("系统初始化")
            log_success "系统初始化完成"
        else
            FAILED_COMPONENTS+=("系统初始化")
            log_error "系统初始化失败"
        fi
    else
        log_error "系统模块不存在: $MODULES_DIR/system.sh"
    fi
}

# 设置镜像源
setup_mirrors() {
    log_info "配置镜像源..."
    
    # Homebrew镜像
    export HOMEBREW_INSTALL_FROM_API=1
    export HOMEBREW_API_DOMAIN=$(read_config '.mirrors.homebrew.api_domain')
    export HOMEBREW_BOTTLE_DOMAIN=$(read_config '.mirrors.homebrew.bottle_domain')
    export HOMEBREW_BREW_GIT_REMOTE=$(read_config '.mirrors.homebrew.brew_git')
    export HOMEBREW_CORE_GIT_REMOTE=$(read_config '.mirrors.homebrew.core_git')
    
    # Rust镜像
    export RUSTUP_DIST_SERVER=$(read_config '.mirrors.rust.dist_server')
    export RUSTUP_UPDATE_ROOT=$(read_config '.mirrors.rust.update_root')
    
    # Node.js镜像
    export NVM_NODEJS_ORG_MIRROR=$(read_config '.mirrors.nodejs.node_mirror')
    
    # Python镜像
    export PYTHON_BUILD_MIRROR_URL=$(read_config '.mirrors.python.build_mirror')
    export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
    
    # Flutter镜像
    export PUB_HOSTED_URL=$(read_config '.mirrors.flutter.pub_hosted_url')
    export FLUTTER_STORAGE_BASE_URL=$(read_config '.mirrors.flutter.storage_base_url')
    
    log_success "镜像源配置完成"
}

# 安装编程语言
install_languages() {
    local selected_languages="$1"
    
    log_info "开始安装编程语言..."
    
    if [ -f "$MODULES_DIR/languages.sh" ]; then
        source "$MODULES_DIR/languages.sh"
        
        # 如果没有指定语言，显示菜单
        if [ -z "$selected_languages" ]; then
            main
        else
            # 安装指定的语言
            for lang in $selected_languages; do
                case "$lang" in
                    "rust") install_rust ;;
                    "nodejs") install_nodejs ;;
                    "python") install_python ;;
                    "golang") install_golang ;;
                    "java") install_java ;;
                    "php") install_php ;;
                    "ruby") install_ruby ;;
                    "flutter") install_flutter ;;
                    *) log_warning "未知语言: $lang" ;;
                esac
            done
        fi
        
        INSTALLED_COMPONENTS+=("编程语言SDK")
    else
        log_error "语言模块不存在: $MODULES_DIR/languages.sh"
        FAILED_COMPONENTS+=("编程语言SDK")
    fi
}

# 安装开发工具
install_dev_tools() {
    local selected_tools="$1"
    
    log_info "开始安装开发工具..."
    
    # 这里可以添加开发工具的安装逻辑
    # 暂时使用简化版本
    
    if [ -z "$selected_tools" ] || [[ $selected_tools == *"neovim"* ]]; then
        install_neovim_simple
    fi
    
    if [ -z "$selected_tools" ] || [[ $selected_tools == *"vscode"* ]]; then
        install_vscode_simple
    fi
    
    INSTALLED_COMPONENTS+=("开发工具")
}

# 简化版Neovim安装
install_neovim_simple() {
    if ! command_exists nvim; then
        log_info "安装 Neovim..."
        brew install neovim ripgrep
        INSTALLED_COMPONENTS+=("Neovim")
    fi
}

# 简化版VSCode安装
install_vscode_simple() {
    if ! brew list --cask visual-studio-code &>/dev/null; then
        log_info "安装 Visual Studio Code..."
        brew install --cask visual-studio-code
        INSTALLED_COMPONENTS+=("Visual Studio Code")
    fi
}

# 安装实用工具
install_utility_tools() {
    log_info "开始安装实用工具..."
    
    local tools=("stats" "karabiner-elements" "apifox")
    
    for tool in "${tools[@]}"; do
        if ! brew list --cask "$tool" &>/dev/null; then
            log_info "安装 $tool..."
            brew install --cask "$tool"
        fi
    done
    
    INSTALLED_COMPONENTS+=("实用工具")
}

# 自定义安装
custom_install() {
    show_component_menu
    read -r selections
    
    # 定义与显示顺序对应的包名 (zsh数组从1开始)
    local display_order=("dev_tools" "languages" "system_init" "utility_tools")
    
    for selection in $selections; do
        if [ $selection -ge 1 ] && [ $selection -le ${#display_order[@]} ]; then
            local package_key="${display_order[$selection]}"
            
            case "$package_key" in
                "system_init") install_system_init ;;
                "languages") install_languages ;;
                "dev_tools") install_dev_tools ;;
                "utility_tools") install_utility_tools ;;
                *) log_warning "未知组件: $package_key" ;;
            esac
        else
            log_warning "无效选项: $selection"
        fi
    done
}

# 显示安装结果
show_results() {
    echo -e "\n${CYAN}安装结果:${NC}"
    echo "========================================"
    
    if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "${GREEN}成功安装的组件:${NC}"
        for component in "${INSTALLED_COMPONENTS[@]}"; do
            echo "  ✓ $component"
        done
    fi
    
    if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "\n${RED}安装失败的组件:${NC}"
        for component in "${FAILED_COMPONENTS[@]}"; do
            echo "  ✗ $component"
        done
    fi
    
    echo "========================================"
    echo -e "${YELLOW}安装日志: $INSTALL_LOG${NC}"
    echo -e "${YELLOW}请重启终端或运行 'source ~/.dev_rc' 以使配置生效${NC}"
}

# 主函数
main() {
    # 初始化
    init_logging
    check_not_root
    check_config
    
    # 显示欢迎界面
    show_welcome
    
    # 系统检查
    system_check
    
    # 主循环
    while true; do
        show_preset_menu
        read -r choice
        
        case $choice in
            0)
                log_info "感谢使用！"
                break
                ;;
            1)
                if confirm_action "确认安装 完整安装"; then
                    install_preset "complete"
                fi
                ;;
            2)
                custom_install
                ;;
            *)
                log_error "无效选项"
                continue
                ;;
        esac
        
        show_results
        wait_for_key "按任意键继续..."
    done
}

# 运行主函数
main "$@"