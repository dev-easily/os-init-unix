# 极简外置开发目录管理

## 概述
完全简化的外置开发目录管理，只保留最基本的功能。

## 核心原理
- 检测外置目录是否存在对应的工具文件夹
- 如果存在就提示用户是否跳过安装
- 就这么简单！

## 添加新工具

在 `common.sh` 的 `DEV_TOOLS` 数组中添加一行：

```bash
declare -gA DEV_TOOLS=(
    ["homebrew"]="/opt/homebrew"
    ["go"]="$HOME/.go"
    ["cargo"]="$HOME/.cargo"
    ["nvm"]="$HOME/.nvm"
    ["pip"]="$HOME/.pip"
    ["m2"]="$HOME/.m2"
    ["pyenv"]="$HOME/.pyenv"
    ["rbenv"]="$HOME/.rbenv"
    ["flutter"]="$HOME/.dev/flutter"
    ["新工具"]="$HOME/.新工具"  # 添加这一行就够了！
)
```

## 在安装脚本中使用

```bash
# 在语言安装函数中
install_rust() {
    # ... 安装逻辑 ...
    
    # 如果设置了外部开发目录，创建软链接
    if [ -n "${DEV_EXTERNAL_PATH:-}" ]; then
        create_dev_link "cargo"  # 就这一行！
    fi
}
```

## 主要函数

- `create_dev_link "工具名"` - 创建软链接
- `detect_existing_software "/外部路径"` - 检测已存在的软件
- `get_tool_path "工具名"` - 获取工具路径

## 检测逻辑

只检查 `/外部路径/工具名/` 目录是否存在，存在就认为已安装。

就这么简单！