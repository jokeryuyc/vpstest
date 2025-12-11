#!/usr/bin/env bash
# 外部脚本跳转模块

MENU_ID=90
MENU_LABEL="外部脚本示例"
MENU_FUNC="module_external_scripts_main"

module_external_scripts_main() {
  local choice
  while true; do
    ui_print_header "外部脚本示例"
    echo "1) 运行 bench.sh 综合测试 (来源: https://bench.sh)"
    echo "2) 运行 YABS 基准测试 (来源: https://github.com/masonr/yet-another-bench-script)"
    echo "0) 返回主菜单"
    echo "------------------------------------"
    read -r -p "请选择: " choice
    case "$choice" in
      1) external_run_script "bench.sh 综合测试" "https://bench.sh" ;;
      2) external_run_script "YABS 基准测试" "https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/yabs.sh" ;;
      0) break ;;
      *) ui_print_error "无效选项，请重试。" ;;
    esac
  done
}

external_run_script() {
  local name="$1"
  local url="$2"

  ui_print_warning "将执行外部脚本: $name"
  ui_print_info "来源: $url"
  if ! ui_confirm "确认继续运行该脚本吗？"; then
    log_info "已取消运行 $name"
    ui_press_enter_to_continue
    return
  fi

  if ! has_command curl && ! has_command wget; then
    ui_print_error "缺少 curl 和 wget，无法下载外部脚本。"
    ui_press_enter_to_continue
    return
  fi

  local tmp
  tmp=$(mktemp -t ytool-XXXX.sh) || {
    ui_print_error "无法创建临时文件。"
    ui_press_enter_to_continue
    return
  }

  if has_command curl; then
    if ! curl -fsSL -o "$tmp" "$url"; then
      ui_print_error "下载失败，请检查网络。"
      rm -f "$tmp"
      ui_press_enter_to_continue
      return
    fi
  else
    if ! wget -q -O "$tmp" "$url"; then
      ui_print_error "下载失败，请检查网络。"
      rm -f "$tmp"
      ui_press_enter_to_continue
      return
    fi
  fi

  chmod +x "$tmp"
  if ! bash "$tmp"; then
    ui_print_error "脚本执行时出现错误。"
  fi
  rm -f "$tmp"
  ui_press_enter_to_continue
}
