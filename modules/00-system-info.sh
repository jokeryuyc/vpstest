#!/usr/bin/env bash
# 基础系统信息模块

MENU_ID=0
MENU_LABEL="系统状态与信息"
MENU_FUNC="module_system_info_main"

module_system_info_main() {
  ui_print_header "系统状态与信息"

  echo "主机名: $(hostname)"

  if has_command hostnamectl; then
    hostnamectl status
  elif [ -f /etc/os-release ]; then
    echo "操作系统:"
    grep -E '^(NAME|VERSION)=' /etc/os-release | sed 's/^/  /'
  else
    echo "操作系统: 未检测到"
  fi

  if has_command uptime; then
    echo "运行时间 / 负载:"
    uptime
  fi

  if has_command lscpu; then
    echo "CPU 信息:"
    lscpu | grep -E '^(Model name|CPU\(s\)|Vendor ID|Architecture)' | sed 's/^/  /'
  elif [ -f /proc/cpuinfo ]; then
    echo "CPU 信息:"
    grep -m1 'model name' /proc/cpuinfo | sed 's/^/  /'
    echo "  核心数: $(grep -c '^processor' /proc/cpuinfo)"
  fi

  if has_command free; then
    echo "内存使用:"
    free -h
  fi

  if has_command df; then
    echo "磁盘使用:"
    df -h -x tmpfs -x devtmpfs
  fi

  ui_press_enter_to_continue
}
