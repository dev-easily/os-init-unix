#!/bin/bash
# 系统初始化模块

# 导入通用函数 (使用 BASH_SOURCE 兼容 source 引入模式)
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Homebrew安装和配置
install_homebrew() {
	if should_skip_installation "homebrew"; then
		log_info "跳过 Homebrew 安装 (外部存储中已存在)"
		# 确保软链接存在
		if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
			create_dev_link "homebrew"
		fi
		# 设置环境变量
		if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
			eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		elif [ -d "/opt/homebrew/bin" ]; then
			eval $(/opt/homebrew/bin/brew shellenv)
		fi
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
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
    export HOMEBREW_CASK_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-cask.git"
    export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
	export HOMEBREW_INSTALL_FROM_API=1
	#export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
	#export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
	#export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
	#export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"

	# Ubuntu 需要先安装依赖
	if is_ubuntu; then
		log_info "更新apt并安装Homebrew依赖..."
		sudo_run apt update
		sudo_run apt install -y build-essential procps curl file git
	fi

	# 下载并安装
	if [ "$DRY_RUN" != "true" ]; then
		/bin/bash "$(dirname "${BASH_SOURCE[0]}")/home_brew_install.sh"
	else
		log_info "[DRY-RUN] would run brew install script"
	fi

	# 设置环境变量
	if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	elif [ -d "/opt/homebrew/bin" ]; then
		eval $(/opt/homebrew/bin/brew shellenv)
	fi

	# 更新
	brew cleanup
	brew update --force
	brew tap --repair

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

	local bashrc_source="$SCRIPT_DIR/config/bashrc.sh"

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
	if [ -f ~/.zshrc ] && ! grep -q "dev_rc" ~/.zshrc 2>/dev/null; then
		echo "" >> ~/.zshrc
		echo "# 开发环境配置" >> ~/.zshrc
		echo "test -f ~/.dev_rc && source ~/.dev_rc" >> ~/.zshrc
		log_info "已配置 zshrc"
	fi

	# 配置bashrc
	if [ -f ~/.bashrc ] && ! grep -q "dev_rc" ~/.bashrc 2>/dev/null; then
		echo "" >> ~/.bashrc
		echo "# 开发环境配置" >> ~/.bashrc
		echo "test -f ~/.dev_rc && source ~/.dev_rc" >> ~/.bashrc
		log_info "已配置 bashrc"
	fi

	# 配置bash_profile
	if [ -f ~/.bash_profile ] && ! grep -q "bashrc" ~/.bash_profile 2>/dev/null; then
		echo "" >> ~/.bash_profile
		echo "# 加载bashrc" >> ~/.bash_profile
		echo "test -f ~/.bashrc && source ~/.bashrc" >> ~/.bash_profile
		log_info "已配置 bash_profile"
	fi

	# 配置profile for Ubuntu
	if is_ubuntu; then
		if [ -f ~/.profile ] && ! grep -q "dev_rc" ~/.profile 2>/dev/null; then
			echo "" >> ~/.profile
			echo "# 开发环境配置" >> ~/.profile
			echo "test -f ~/.dev_rc && source ~/.dev_rc" >> ~/.profile
			log_info "已配置 profile"
		fi
	fi

	log_success "Shell 环境配置完成"
}

# 安装基础工具
install_basic_tools() {
	log_info "安装基础工具..."

	local tools=(
		"curl"
		"wget"
		"vim"
		"tree"
		"htop"
		"jq"
		"unzip"
	)

	# Git已经在主脚本中检查安装过了，但如果brew有更新版本可以安装
	if ! command_exists git; then
		tools+=("git")
	fi

	# Ubuntu上connect叫做connect-proxy
	if is_ubuntu; then
		if ! brew list connect-proxy &>/dev/null; then
			if command_exists apt; then
				sudo_run apt install -y connect-proxy
			fi
		fi
	else
		tools+=("connect")
		tools+=("bash")
	fi

	for tool in "${tools[@]}"; do
		if ! brew list "$tool" &>/dev/null; then
			log_info "安装 $tool..."
			run brew install "$tool"
		else
			log_info "$tool 已安装，跳过"
		fi
	done

	log_success "基础工具安装完成"
}

# Docker安装
install_docker() {
	if is_macos; then
		if brew list --cask docker &>/dev/null; then
			log_info "Docker 已安装，跳过"
			return 0
		fi

		log_info "安装 Docker..."
		run brew install --cask docker
		log_success "Docker 安装完成"
	elif is_ubuntu; then
		if command_exists docker; then
			log_info "Docker 已安装，跳过"
			return 0
		fi
		log_info "安装 Docker via apt..."
		if [ "$DRY_RUN" != "true" ]; then
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		else
			log_info "[DRY-RUN] would add Docker apt repository"
		fi
		sudo_run apt update
		sudo_run apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
		log_success "Docker 安装完成，请重新登录后使用"
	fi
}

# 系统优化
optimize_system() {
	log_info "优化系统设置..."

	if is_macos; then
		# 这里可以放macOS特定优化
		:
	elif is_ubuntu; then
		# Ubuntu通用优化
		:
	fi

	log_success "系统优化完成"
}

# 主函数
main() {
	log_info "开始系统初始化..."

	# 开发目录配置 (在安装其他组件之前)
	if confirm_action "是否配置开发目录管理 (推荐)"; then
		configure_dev_directory
	fi

	configure_shell
	install_homebrew
	install_basic_tools
	install_docker
	configure_git

	if confirm_action "是否进行系统优化"; then
		optimize_system
	fi

	log_success "系统初始化完成！请重启终端以使配置生效。"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
