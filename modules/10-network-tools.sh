#!/usr/bin/env bash
# 网络工具模块

MENU_ID=10
MENU_LABEL="网络与连通性工具"
MENU_FUNC="module_network_tools_main"

module_network_tools_main() {
  local choice
  while true; do
    ui_print_header "网络与连通性工具"
    echo "1) Ping 主机"
    echo "2) 查看本机 IP 信息"
    echo "3) 测试 HTTP/HTTPS 连通性"
    echo "4) 简易速度测试"
    echo "0) 返回主菜单"
    echo "------------------------------------"
    read -r -p "请选择: " choice
    case "$choice" in
      1) nettool_ping_host ;;
      2) nettool_show_ip ;;
      3) nettool_http_test ;;
      4) nettool_speed_test ;;
      0) break ;;
      *) ui_print_error "无效选项，请重试。" ;;
    esac
  done
}

nettool_ping_host() {
  if ! has_command ping; then
    ui_print_error "未找到 ping 命令。"
    ui_press_enter_to_continue
    return
  fi
  local target
  read -r -p "请输入目标主机或 IP（默认 8.8.8.8）: " target
  target="${target:-8.8.8.8}"
  echo "正在 Ping $target ..."
  if ! ping -c 4 "$target"; then
    ui_print_error "Ping 失败，请检查网络或目标地址。"
  fi
  ui_press_enter_to_continue
}

nettool_show_ip() {
  ui_print_header "IP 信息"
  if has_command ip; then
    ip addr show
  elif has_command ifconfig; then
    ifconfig
  else
    ui_print_error "未找到 ip/ifconfig 命令。"
  fi
  ui_press_enter_to_continue
}

nettool_http_test() {
  local url
  read -r -p "输入要测试的 URL（默认 https://example.com）: " url
  url="${url:-https://example.com}"
  if has_command curl; then
    echo "使用 curl 测试 $url ..."
    if ! curl -I -m 10 -L "$url"; then
      ui_print_error "请求失败，请检查地址或网络。"
    fi
  elif has_command wget; then
    echo "使用 wget 测试 $url ..."
    if ! wget --server-response --spider -T 10 "$url"; then
      ui_print_error "请求失败，请检查地址或网络。"
    fi
  else
    ui_print_error "缺少 curl 或 wget，无法测试。"
  fi
  ui_press_enter_to_continue
}

nettool_speed_test() {
  ui_print_header "简易速度测试"
  if has_command speedtest; then
    speedtest
  elif has_command fast; then
    fast
  elif has_command curl; then
    echo "未找到 speedtest/fast，尝试使用 curl 测试下载速度（下载小文件）"
    if ! curl -o /dev/null -L --progress-bar --max-time 30 "https://speed.cloudflare.com/__down?bytes=5000000"; then
      ui_print_error "速度测试失败，请检查网络。"
    fi
  else
    ui_print_error "缺少 curl，无法进行速度测试。"
  fi
  ui_press_enter_to_continue
}
