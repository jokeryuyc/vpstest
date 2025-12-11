#!/usr/bin/env bash
# shellcheck shell=bash

# 打印分隔标题
ui_print_header() {
  local title="${1:-}"
  local line
  line=$(printf '=%.0s' {1..50})
  echo
  printf "%s\n" "$line"
  printf " %s\n" "$(color_bold "$title")"
  printf "%s\n" "$line"
}

# 轻量提示
ui_print_info() { printf "%s %s\n" "$(color_blue "[i]")" "$*"; }
ui_print_warning() { printf "%s %s\n" "$(color_yellow "[!]")" "$*"; }
ui_print_error() { printf "%s %s\n" "$(color_red "[x]")" "$*"; }

# 等待用户确认继续
ui_press_enter_to_continue() {
  read -r -p "按 Enter 返回主菜单..." _
}

# 简单确认，返回 0 表示确认
ui_confirm() {
  local question="${1:-继续?}"
  local reply
  read -r -p "$question [y/N]: " reply
  case "${reply,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}
