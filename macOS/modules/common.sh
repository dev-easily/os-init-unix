#!/bin/zsh
# 通用函数库

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "${DEBUG:-}" = "1" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# 进度条函数
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r${CYAN}["
    for ((i=0; i<completed; i++)); do
        printf "="
    done
    printf ">"
    for ((i=completed; i<width; i++)); do
        printf " "
    done
    printf "] %d%% (%d/%d)${NC}" "$percentage" "$current" "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否为macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# 检查macOS版本
get_macos_version() {
    sw_vers -productVersion
}

# 检查是否为Apple Silicon
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

# 确认操作
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        echo -n -e "${YELLOW}$message [Y/n]: ${NC}"
    else
        echo -n -e "${YELLOW}$message [y/N]: ${NC}"
    fi
    
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            log_warning "无效输入，请输入 y 或 n"
            confirm_action "$message" "$default"
            ;;
    esac
}

# 等待用户按键
wait_for_key() {
    local message="${1:-按任意键继续...}"
    echo -e "\n${GREEN}$message${NC}"
    
    # 兼容不同shell的read命令
    if [ -n "$ZSH_VERSION" ]; then
        # zsh
        read -k 1
    elif [ -n "$BASH_VERSION" ]; then
        # bash
        read -n 1 -s
    else
        # 通用方式
        read dummy
    fi
    echo
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    if ping -c 1 -W 3000 google.com >/dev/null 2>&1 || ping -c 1 -W 3000 baidu.com >/dev/null 2>&1; then
        log_success "网络连接正常"
        return 0
    else
        log_warning "网络连接检查失败，但将继续安装"
        return 0  # 不阻止安装过程
    fi
}

# 检查磁盘空间
check_disk_space() {
    local required_gb=${1:-10}
    local available_gb=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G.*//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        log_error "磁盘空间不足，需要至少 ${required_gb}GB，当前可用 ${available_gb}GB"
        return 1
    else
        log_info "磁盘空间充足，可用 ${available_gb}GB"
        return 0
    fi
}

# 创建备份
create_backup() {
    local file="$1"
    local backup_dir="$HOME/.config_backup/$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        mkdir -p "$backup_dir"
        cp "$file" "$backup_dir/"
        log_info "已备份 $file 到 $backup_dir/"
    fi
}

# 安全下载文件
safe_download() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        log_info "下载 $url (尝试 $((retry + 1))/$max_retries)..."
        
        if curl -fsSL --connect-timeout 10 --max-time 300 "$url" -o "$output"; then
            log_success "下载完成: $output"
            return 0
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_warning "下载失败，3秒后重试..."
                sleep 3
            fi
        fi
    done
    
    log_error "下载失败: $url"
    return 1
}

# 验证文件哈希
verify_hash() {
    local file="$1"
    local expected_hash="$2"
    local hash_type="${3:-sha256}"
    
    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    local actual_hash
    case "$hash_type" in
        "md5")
            actual_hash=$(md5 -q "$file")
            ;;
        "sha1")
            actual_hash=$(shasum -a 1 "$file" | cut -d' ' -f1)
            ;;
        "sha256")
            actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
            ;;
        *)
            log_error "不支持的哈希类型: $hash_type"
            return 1
            ;;
    esac
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        log_success "文件哈希验证通过"
        return 0
    else
        log_error "文件哈希验证失败"
        log_error "期望: $expected_hash"
        log_error "实际: $actual_hash"
        return 1
    fi
}

# 添加到PATH
add_to_path() {
    local new_path="$1"
    local shell_rc="$2"
    
    if [ -z "$shell_rc" ]; then
        shell_rc="$HOME/.dev_rc"
    fi
    
    if ! grep -q "$new_path" "$shell_rc" 2>/dev/null; then
        echo "export PATH=\"$new_path:\$PATH\"" >> "$shell_rc"
        log_info "已添加 $new_path 到 PATH"
    fi
}

# 设置环境变量
set_env_var() {
    local var_name="$1"
    local var_value="$2"
    local shell_rc="${3:-$HOME/.dev_rc}"
    
    if ! grep -q "export $var_name=" "$shell_rc" 2>/dev/null; then
        echo "export $var_name=\"$var_value\"" >> "$shell_rc"
        log_info "已设置环境变量 $var_name"
    fi
}

# 检查并创建目录 (支持软链接)
ensure_dir() {
    local dir="$1"
    
    # 如果目录已存在（包括软链接指向的目录），直接返回
    if [ -d "$dir" ]; then
        return 0
    fi
    
    # 如果是软链接但目标不存在
    if [ -L "$dir" ]; then
        local target=$(readlink "$dir")
        log_info "软链接 $dir 指向 $target"
        
        # 如果是相对路径，转换为绝对路径
        if [[ "$target" != /* ]]; then
            target="$(dirname "$dir")/$target"
        fi
        
        # 确保目标目录存在
        if [ ! -d "$target" ]; then
            mkdir -p "$target"
            log_info "已创建软链接目标目录: $target"
        fi
        
        return 0
    fi
    
    # 普通目录创建
    mkdir -p "$dir"
    log_info "已创建目录: $dir"
}

# 安全创建目录 (检查软链接完整性)
ensure_dir_safe() {
    local dir="$1"
    local create_target="${2:-true}"
    
    # 如果目录存在且可访问，直接返回
    if [ -d "$dir" ] && [ -r "$dir" ] && [ -w "$dir" ]; then
        return 0
    fi
    
    # 如果是软链接
    if [ -L "$dir" ]; then
        local target=$(readlink "$dir")
        
        # 转换相对路径为绝对路径
        if [[ "$target" != /* ]]; then
            target="$(cd "$(dirname "$dir")" && pwd)/$target"
        fi
        
        log_info "检查软链接: $dir -> $target"
        
        # 检查目标是否存在
        if [ ! -d "$target" ]; then
            if [ "$create_target" = "true" ]; then
                mkdir -p "$target"
                log_success "已创建软链接目标目录: $target"
            else
                log_error "软链接目标不存在且不允许创建: $target"
                return 1
            fi
        fi
        
        # 检查软链接是否有效
        if [ ! -d "$dir" ]; then
            log_error "软链接无效: $dir -> $target"
            return 1
        fi
        
        # 检查权限
        if [ ! -w "$dir" ]; then
            log_error "软链接目标目录不可写: $target"
            return 1
        fi
        
        log_success "软链接检查通过: $dir -> $target"
        return 0
    fi
    
    # 如果路径存在但不是目录
    if [ -e "$dir" ]; then
        log_error "$dir 存在但不是目录"
        return 1
    fi
    
    # 创建普通目录
    mkdir -p "$dir"
    log_success "已创建目录: $dir"
    return 0
}

# 智能目录确保 (根据开发目录配置自动处理)
ensure_dev_dir() {
    local dir="$1"
    local tool_name="$2"
    
    # 如果设置了外部开发目录且这是开发相关目录
    if [ -n "${DEV_EXTERNAL_PATH:-}" ] && [ -n "$tool_name" ]; then
        # 检查是否需要创建软链接
        local external_path="$DEV_EXTERNAL_PATH/$tool_name"
        
        # 如果目录不存在或不是软链接，创建软链接
        if [ ! -L "$dir" ]; then
            create_dev_symlink "$tool_name" "$dir" "$DEV_EXTERNAL_PATH"
        fi
        
        # 确保软链接目标存在
        ensure_dir_safe "$dir" true
    else
        # 普通目录处理
        ensure_dir "$dir"
    fi
}

# 检查软链接状态
check_symlink_status() {
    local link_path="$1"
    
    if [ ! -e "$link_path" ]; then
        echo "not_exist"
        return 1
    elif [ -L "$link_path" ]; then
        local target=$(readlink "$link_path")
        if [ -d "$link_path" ]; then
            echo "valid_symlink:$target"
            return 0
        else
            echo "broken_symlink:$target"
            return 1
        fi
    elif [ -d "$link_path" ]; then
        echo "regular_directory"
        return 0
    else
        echo "file_exists"
        return 1
    fi
}

# 检测外部存储中已存在的软件
detect_existing_software() {
    local external_dev_path="$1"
    
    log_info "检测外部存储中已存在的软件..."
    
    # 定义软件检查路径
    local homebrew_check="$external_dev_path/homebrew/bin/brew"
    local go_check="$external_dev_path/go/bin"
    local cargo_check="$external_dev_path/cargo/bin/cargo"
    local nvm_check="$external_dev_path/nvm/nvm.sh"
    local pip_check="$external_dev_path/pip/pip.conf"
    local m2_check="$external_dev_path/m2/repository"
    local pyenv_check="$external_dev_path/pyenv/bin/pyenv"
    local rbenv_check="$external_dev_path/rbenv/bin/rbenv"
    local flutter_check="$external_dev_path/flutter/bin/flutter"
    
    local existing_software=()
    
    # 检查各个软件
    [ -e "$homebrew_check" ] && existing_software+=("homebrew") && log_success "✓ 检测到已存在的 homebrew: $homebrew_check"
    [ -e "$go_check" ] && existing_software+=("go") && log_success "✓ 检测到已存在的 go: $go_check"
    [ -e "$cargo_check" ] && existing_software+=("cargo") && log_success "✓ 检测到已存在的 cargo: $cargo_check"
    [ -e "$nvm_check" ] && existing_software+=("nvm") && log_success "✓ 检测到已存在的 nvm: $nvm_check"
    [ -e "$pip_check" ] && existing_software+=("pip") && log_success "✓ 检测到已存在的 pip: $pip_check"
    [ -e "$m2_check" ] && existing_software+=("m2") && log_success "✓ 检测到已存在的 m2: $m2_check"
    [ -e "$pyenv_check" ] && existing_software+=("pyenv") && log_success "✓ 检测到已存在的 pyenv: $pyenv_check"
    [ -e "$rbenv_check" ] && existing_software+=("rbenv") && log_success "✓ 检测到已存在的 rbenv: $rbenv_check"
    [ -e "$flutter_check" ] && existing_software+=("flutter") && log_success "✓ 检测到已存在的 flutter: $flutter_check"
    
    if [ ${#existing_software[@]} -gt 0 ]; then
        echo -e "\n${CYAN}发现以下软件已存在于外部存储:${NC}"
        for software in "${existing_software[@]}"; do
            echo "  • $software"
        done
        echo ""
        
        if confirm_action "是否跳过已存在软件的安装"; then
            # 导出已存在软件列表供其他函数使用
            export EXISTING_SOFTWARE="${existing_software[*]}"
            log_info "将跳过已存在软件的安装"
        else
            export EXISTING_SOFTWARE=""
            log_info "将重新安装所有软件"
        fi
    else
        log_info "外部存储中未发现已安装的软件"
        export EXISTING_SOFTWARE=""
    fi
}

# 检查软件是否应该跳过安装
should_skip_installation() {
    local software_name="$1"
    
    if [ -n "${EXISTING_SOFTWARE:-}" ]; then
        if [[ " $EXISTING_SOFTWARE " == *" $software_name "* ]]; then
            return 0  # 应该跳过
        fi
    fi
    
    return 1  # 不应该跳过
}

# 智能软件安装包装器
smart_install() {
    local software_name="$1"
    local install_function="$2"
    shift 2
    local install_args=("$@")
    
    if should_skip_installation "$software_name"; then
        log_info "跳过 $software_name 安装 (外部存储中已存在)"
        return 0
    fi
    
    log_info "开始安装 $software_name..."
    if "$install_function" "${install_args[@]}"; then
        log_success "$software_name 安装完成"
        return 0
    else
        log_error "$software_name 安装失败"
        return 1
    fi
}

# 清理临时文件
cleanup_temp() {
    local temp_dir="${1:-/tmp/macos_setup_$$}"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        log_info "已清理临时文件: $temp_dir"
    fi
}

# 错误处理
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if [ $exit_code -ne 0 ]; then
        log_error "脚本在第 $line_number 行出错，退出码: $exit_code"
        cleanup_temp
        exit $exit_code
    fi
}

# 设置错误处理
set_error_handling() {
    set -e
    trap 'handle_error $LINENO' ERR
}

# 显示系统信息
show_system_info() {
    echo -e "${CYAN}系统信息:${NC}"
    echo "操作系统: $(sw_vers -productName) $(sw_vers -productVersion)"
    echo "架构: $(uname -m)"
    echo "内核: $(uname -r)"
    echo "用户: $(whoami)"
    echo "主目录: $HOME"
    echo "Shell: $SHELL"
    echo ""
}

# 检查依赖
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        return 1
    else
        log_success "所有依赖已满足"
        return 0
    fi
}

# 显示安装摘要
show_summary() {
    local installed=("$@")
    
    echo -e "\n${GREEN}安装摘要:${NC}"
    echo "========================================"
    
    if [ ${#installed[@]} -gt 0 ]; then
        echo -e "${GREEN}已安装的组件:${NC}"
        for item in "${installed[@]}"; do
            echo "  ✓ $item"
        done
    else
        echo "没有安装任何组件"
    fi
    
    echo "========================================"
    echo -e "${YELLOW}提示: 请重启终端或运行 'source ~/.dev_rc' 以使配置生效${NC}"
}

# 检查root权限
check_not_root() {
    if [ $(id -u) -eq 0 ]; then
        log_error "请不要以root用户运行此脚本"
        exit 1
    fi
}

# 检查Xcode Command Line Tools
check_xcode_tools() {
    if ! xcode-select -p >/dev/null 2>&1; then
        log_warning "未检测到 Xcode Command Line Tools"
        if confirm_action "是否安装 Xcode Command Line Tools"; then
            xcode-select --install
            log_info "请在弹出的对话框中完成安装，然后重新运行此脚本"
            exit 0
        else
            log_error "需要 Xcode Command Line Tools 才能继续"
            exit 1
        fi
    else
        log_success "Xcode Command Line Tools 已安装"
    fi
}

# 开发目录管理
setup_dev_directory() {
    local external_dev_path="$1"
    local home_dev_link="$HOME/.dev"
    
    log_info "设置开发目录管理..."
    
    # 检查外部路径是否存在
    if [ ! -d "$(dirname "$external_dev_path")" ]; then
        log_error "外部存储路径不存在: $(dirname "$external_dev_path")"
        return 1
    fi
    
    # 创建外部开发目录
    ensure_dir "$external_dev_path"
    
    # 如果 ~/.dev 已存在且不是软链接，备份它
    if [ -d "$home_dev_link" ] && [ ! -L "$home_dev_link" ]; then
        local backup_dir="${home_dev_link}_backup_$(date +%Y%m%d_%H%M%S)"
        log_warning "~/.dev 目录已存在，备份到 $backup_dir"
        mv "$home_dev_link" "$backup_dir"
    fi
    
    # 删除现有的软链接（如果存在）
    if [ -L "$home_dev_link" ]; then
        rm "$home_dev_link"
    fi
    
    # 创建软链接
    ln -sf "$external_dev_path" "$home_dev_link"
    log_success "已创建开发目录软链接: $home_dev_link -> $external_dev_path"
    
    return 0
}

# 创建开发工具目录软链接
create_dev_symlink() {
    local tool_name="$1"
    local home_path="$2"
    local external_base="$3"
    
    local external_path="$external_base/$tool_name"
    
    log_info "设置 $tool_name 目录软链接..."
    
    # 确保外部目录存在
    ensure_dir "$external_path"
    
    # 如果home路径已存在且不是软链接，移动内容到外部目录
    if [ -d "$home_path" ] && [ ! -L "$home_path" ]; then
        log_info "迁移现有 $tool_name 数据到外部存储..."
        
        # 如果外部目录为空，移动所有内容
        if [ -z "$(ls -A "$external_path" 2>/dev/null)" ]; then
            mv "$home_path"/* "$external_path"/ 2>/dev/null || true
            mv "$home_path"/.[^.]* "$external_path"/ 2>/dev/null || true
        else
            log_warning "外部目录不为空，跳过数据迁移"
        fi
        
        # 删除原目录
        rm -rf "$home_path"
    elif [ -L "$home_path" ]; then
        log_info "$tool_name 软链接已存在，跳过"
        return 0
    fi
    
    # 确保父目录存在（特别是对于flutter这种在子目录中的情况）
    local parent_dir="$(dirname "$home_path")"
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi
    
    # 创建软链接
    ln -sf "$external_path" "$home_path"
    log_success "已创建 $tool_name 软链接: $home_path -> $external_path"
}

# 设置所有开发工具的软链接
setup_all_dev_symlinks() {
    local external_dev_path="$1"
    
    log_info "设置开发工具目录软链接..."
    
    # 定义需要软链接的目录
    local dev_dirs=(
        "go:$HOME/go"
        "cargo:$HOME/.cargo"
        "nvm:$HOME/.nvm"
        "pip:$HOME/.pip"
        "m2:$HOME/.m2"
        "pyenv:$HOME/.pyenv"
        "rbenv:$HOME/.rbenv"
        "flutter:$HOME/.dev/flutter"
    )
    
    for dir_info in "${dev_dirs[@]}"; do
        local tool_name="${dir_info%%:*}"
        local home_path="${dir_info##*:}"
        
        create_dev_symlink "$tool_name" "$home_path" "$external_dev_path"
    done
    
    log_success "所有开发工具目录软链接设置完成"
}

# 根据配置文件设置开发工具软链接
setup_configured_dev_symlinks() {
    local external_dev_path="$1"
    shift
    local symlink_dirs=("$@")
    
    log_info "根据配置文件设置开发工具目录软链接..."
    
    # 定义工具名到路径的映射
    declare -A tool_paths=(
        ["homebrew"]="/opt/homebrew"
        ["go"]="$HOME/go"
        ["cargo"]="$HOME/.cargo"
        ["nvm"]="$HOME/.nvm"
        ["pip"]="$HOME/.pip"
        ["m2"]="$HOME/.m2"
        ["pyenv"]="$HOME/.pyenv"
        ["rbenv"]="$HOME/.rbenv"
        ["flutter"]="$HOME/.dev/flutter"
    )
    
    for tool_name in "${symlink_dirs[@]}"; do
        local home_path="${tool_paths[$tool_name]}"
        
        if [ -n "$home_path" ]; then
            create_dev_symlink "$tool_name" "$home_path" "$external_dev_path"
        else
            log_warning "未知的开发工具: $tool_name"
        fi
    done
    
    log_success "配置文件指定的开发工具目录软链接设置完成"
}

# 检查外部存储设备
check_external_storage() {
    local mount_point="$1"
    
    if [ ! -d "$mount_point" ]; then
        log_error "外部存储设备未挂载: $mount_point"
        return 1
    fi
    
    # 检查是否可写
    if [ ! -w "$mount_point" ]; then
        log_error "外部存储设备不可写: $mount_point"
        return 1
    fi
    
    # 检查可用空间 (至少需要5GB)
    local available_gb=$(df -h "$mount_point" | awk 'NR==2 {print $4}' | sed 's/G.*//')
    if [ "$available_gb" -lt 5 ]; then
        log_warning "外部存储可用空间不足5GB: ${available_gb}GB"
        if ! confirm_action "是否继续"; then
            return 1
        fi
    fi
    
    log_success "外部存储设备检查通过: $mount_point (可用: ${available_gb}GB)"
    return 0
}

# 显示开发目录设置菜单
show_dev_directory_menu() {
    # 从配置文件读取默认路径
    local default_path="/Volumes/1T/dev"
    if command_exists jq && [ -f "$CONFIG_FILE" ]; then
        local config_path=$(jq -r '.user_config.dev_directory.default_external_path // "/Volumes/1T/dev"' "$CONFIG_FILE" 2>/dev/null)
        if [ "$config_path" != "null" ] && [ -n "$config_path" ]; then
            default_path="$config_path"
        fi
    fi
    
    echo -e "\n${YELLOW}开发目录管理:${NC}"
    echo "为了节省系统盘空间，建议将开发相关目录链接到外部存储"
    echo ""
    echo "将会设置以下目录的软链接:"
    echo "  • ~/.dev        -> 外部存储/dev"
    echo "  • ~/go         -> 外部存储/dev/go"
    echo "  • ~/.cargo     -> 外部存储/dev/cargo"
    echo "  • ~/.nvm       -> 外部存储/dev/nvm"
    echo "  • ~/.pip       -> 外部存储/dev/pip"
    echo "  • ~/.m2        -> 外部存储/dev/m2"
    echo "  • ~/.pyenv     -> 外部存储/dev/pyenv"
    echo "  • ~/.rbenv     -> 外部存储/dev/rbenv"
    echo ""
    echo "外部存储路径选项:"
    echo "1. $default_path (配置文件默认)"
    echo "2. /Volumes/External/dev"
    echo "3. 自定义路径"
    echo "4. 跳过设置"
    echo -n -e "\n${BLUE}请选择 [1-4]: ${NC}"
}

# 配置开发目录
configure_dev_directory() {
    # 从配置文件读取设置
    local default_path="/Volumes/1T/dev"
    local enabled=true
    local symlink_dirs=()
    
    if command_exists jq && [ -f "$CONFIG_FILE" ]; then
        # 读取配置文件设置
        local config_enabled=$(jq -r '.user_config.dev_directory.enabled // true' "$CONFIG_FILE" 2>/dev/null)
        local config_path=$(jq -r '.user_config.dev_directory.default_external_path // "/Volumes/1T/dev"' "$CONFIG_FILE" 2>/dev/null)
        
        if [ "$config_enabled" = "false" ]; then
            log_info "开发目录管理已在配置文件中禁用"
            return 0
        fi
        
        if [ "$config_path" != "null" ] && [ -n "$config_path" ]; then
            default_path="$config_path"
        fi
        
        # 读取软链接目录列表
        local dirs_json=$(jq -r '.user_config.dev_directory.symlink_dirs[]?' "$CONFIG_FILE" 2>/dev/null)
        if [ -n "$dirs_json" ]; then
            while IFS= read -r dir; do
                [ -n "$dir" ] && symlink_dirs+=("$dir")
            done <<< "$dirs_json"
        fi
    fi
    
    # 如果配置文件中没有定义，使用默认列表
    if [ ${#symlink_dirs[@]} -eq 0 ]; then
        symlink_dirs=("go" "cargo" "nvm" "pip" "m2" "pyenv" "rbenv" "flutter")
    fi
    
    show_dev_directory_menu
    read -r choice
    
    local external_dev_path=""
    
    case $choice in
        1)
            external_dev_path="$default_path"
            ;;
        2)
            external_dev_path="/Volumes/External/dev"
            ;;
        3)
            echo -n -e "${BLUE}请输入外部存储路径: ${NC}"
            read -r external_dev_path
            ;;
        4)
            log_info "跳过开发目录设置"
            return 0
            ;;
        *)
            log_error "无效选项"
            return 1
            ;;
    esac
    
    # 检查外部存储
    if ! check_external_storage "$(dirname "$external_dev_path")"; then
        return 1
    fi
    
    # 确认设置
    echo -e "\n${CYAN}将设置开发目录到: $external_dev_path${NC}"
    echo -e "${CYAN}将管理以下目录: ${symlink_dirs[*]}${NC}"
    
    if confirm_action "确认设置开发目录软链接"; then
        setup_dev_directory "$external_dev_path"
        
        # 检测已存在的软件
        if [ "$(read_config '.user_config.dev_directory.detect_existing // true')" = "true" ]; then
            detect_existing_software "$external_dev_path"
        fi
        
        # 使用配置文件中的目录列表设置软链接
        setup_configured_dev_symlinks "$external_dev_path" "${symlink_dirs[@]}"
        
        # 保存配置到环境文件
        local shell_rc="$HOME/.dev_rc"
        if ! grep -q "DEV_EXTERNAL_PATH" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# 外部开发目录配置" >> "$shell_rc"
            echo "export DEV_EXTERNAL_PATH=\"$external_dev_path\"" >> "$shell_rc"
        fi
        
        log_success "开发目录配置完成"
        return 0
    else
        log_info "已取消开发目录设置"
        return 1
    fi
}