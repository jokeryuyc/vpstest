#!/usr/bin/env bash
# 常用工具安装模块

MENU_ID=20
MENU_LABEL="安装常用工具"
MENU_FUNC="module_install_tools_main"

module_install_tools_main() {
  local choice
  while true; do
    ui_print_header "安装常用工具"
    echo "1) 安装 htop"
    echo "2) 安装 curl"
    echo "3) 安装 git"
    echo "0) 返回主菜单"
    echo "------------------------------------"
    read -r -p "请选择: " choice
    case "$choice" in
      1) install_tool "htop" ;;
      2) install_tool "curl" ;;
      3) install_tool "git" ;;
      0) break ;;
      *) ui_print_error "无效选项，请重试。" ;;
    esac
  done
}

install_tool() {
  local pkg="$1"
  local pm
  pm=$(detect_pkg_manager)
  if [ -z "$pm" ]; then
    ui_print_error "未检测到可用的包管理器。"
    ui_press_enter_to_continue
    return
  fi

  ui_print_info "将使用 $pm 安装 $pkg"
  if ! ui_confirm "确认安装 $pkg?"; then
    log_info "已取消安装 $pkg"
    ui_press_enter_to_continue
    return
  fi

  if install_package_with_pm "$pkg" "$pm"; then
    log_info "$pkg 安装完成"
  else
    log_error "$pkg 安装失败，请检查输出信息。"
  fi
  ui_press_enter_to_continue
}

install_package_with_pm() {
  local pkg="$1"
  local pm="$2"
  local runner=()

  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if can_use_sudo; then
      runner=(sudo)
    else
      log_error "当前非 root 且无法使用 sudo，请以 root 运行后再试。"
      return 1
    fi
  fi

  case "$pm" in
    apt)
      "${runner[@]}" apt-get update -y && "${runner[@]}" apt-get install -y "$pkg"
      ;;
    dnf)
      "${runner[@]}" dnf install -y "$pkg"
      ;;
    yum)
      "${runner[@]}" yum install -y "$pkg"
      ;;
    pacman)
      "${runner[@]}" pacman -Sy --noconfirm "$pkg"
      ;;
    *)
      log_error "暂不支持的包管理器: $pm"
      return 1
      ;;
  esac
}
