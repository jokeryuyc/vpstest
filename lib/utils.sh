#!/usr/bin/env bash
# shellcheck shell=bash

# 判断命令是否存在
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# 日志输出
log_info() { printf "%s %s\n" "$(color_green "[INFO]")" "$*"; }
log_warn() { printf "%s %s\n" "$(color_yellow "[WARN]")" "$*"; }
log_error() { printf "%s %s\n" "$(color_red "[ERROR]")" "$*"; }

# 需要 root 时的检查
require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    log_error "此操作需要 root 权限，请使用 sudo 或切换到 root 后再试。"
    exit 1
  fi
}

# 检测可用的包管理器
detect_pkg_manager() {
  local mgr=""
  if has_command apt-get; then
    mgr="apt"
  elif has_command dnf; then
    mgr="dnf"
  elif has_command yum; then
    mgr="yum"
  elif has_command pacman; then
    mgr="pacman"
  fi
  printf "%s" "$mgr"
}

# 检查 sudo 可用性
can_use_sudo() {
  if has_command sudo && sudo -n true >/dev/null 2>&1; then
    return 0
  fi
  if has_command sudo; then
    # 尝试交互式 sudo，若失败则返回 1
    sudo -v >/dev/null 2>&1 || return 1
    return 0
  fi
  return 1
}
