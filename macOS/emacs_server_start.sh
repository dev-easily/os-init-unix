#!/bin/zsh
# 拖到通用，登录项中
if ps -ef|grep emacs|grep daemon;then
  exit 0
fi

if command -v emacs;then
  emacs --daemon
fi
