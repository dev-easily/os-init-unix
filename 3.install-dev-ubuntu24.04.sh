#!/bin/bash
# db

cat > ~/.ssh/config <<EOF
Host github.com
  HostName ssh.github.com
  User git
  ProxyCommand connect -S 127.0.0.1:7897 %h %p
EOF
