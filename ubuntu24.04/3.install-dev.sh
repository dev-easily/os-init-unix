#!/bin/bash
ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)
source $ROOT_DIR/common/common.sh

# 代理
cat > ~/.ssh/config <<EOF
Host github.com
  HostName ssh.github.com
  User git
  ProxyCommand connect -S 127.0.0.1:7897 %h %p
EOF

# docker
# docker 加速 https://github.com/For-Backup/CF-Workers-docker.io
# yu@kde:~/Projects/gh-proxy$ sudo cat /etc/docker/daemon.json
# {
#   "registry-mirrors": ["https://dh.jiasu.in", "https://hub.dockerx.org"]
# }

# docker 配合私有仓库，将一些常用镜像拉取到本地，push到自己私有仓库
# 用哪个 linux 用户登录，就用哪个 push。如果你用了 sudo，就一直用 sudo。
# sudo docker login --username=你的用户名 registry.cn-hangzhou.aliyuncs.com
# sudo docker tag 镜像ID registry.cn-hangzhou.aliyuncs.com/你的命名空间/你的镜像仓库:版本号 
# sudo docker push registry.cn-hangzhou.aliyuncs.com/你的命名空间/你的镜像仓库:版本号 