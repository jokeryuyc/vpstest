#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BASE_DIR/lib"
MODULE_DIR="$BASE_DIR/modules"

# 基础文件检查
for req in "$LIB_DIR/colors.sh" "$LIB_DIR/ui.sh" "$LIB_DIR/utils.sh"; do
  if [ ! -f "$req" ]; then
    echo "缺少必要文件: $req" >&2
    exit 1
  fi
done

# shellcheck source=lib/colors.sh
source "$LIB_DIR/colors.sh"
# shellcheck source=lib/ui.sh
source "$LIB_DIR/ui.sh"
# shellcheck source=lib/utils.sh
source "$LIB_DIR/utils.sh"

shopt -s nullglob
declare -a MODULE_IDS MODULE_LABELS MODULE_FUNCS MODULE_SOURCES
shopt -u nullglob

# 发现并加载模块
load_modules() {
  shopt -s nullglob
  local module_file
  for module_file in "$MODULE_DIR"/*.sh; do
    case "$module_file" in
      *.example) continue ;;
    esac
    MENU_ID=""
    MENU_LABEL=""
    MENU_FUNC=""
    # shellcheck disable=SC1090
    source "$module_file"
    local mid="${MENU_ID:-}"
    local mlabel="${MENU_LABEL:-}"
    local mfunc="${MENU_FUNC:-}"
    if [ -z "$mid" ] || [ -z "$mlabel" ] || [ -z "$mfunc" ]; then
      log_warn "跳过模块（缺少元数据）: $module_file"
      continue
    fi
    if ! declare -F "$mfunc" >/dev/null 2>&1; then
      log_error "模块函数未定义: $mfunc ($module_file)"
      continue
    fi
    MODULE_IDS+=("$mid")
    MODULE_LABELS+=("$mlabel")
    MODULE_FUNCS+=("$mfunc")
    MODULE_SOURCES+=("$module_file")
    unset MENU_ID MENU_LABEL MENU_FUNC
  done
  shopt -u nullglob
}

# 按 MENU_ID 排序模块（简单冒泡）
sort_modules() {
  local count=${#MODULE_IDS[@]}
  local i j
  for ((i = 0; i < count; i++)); do
    for ((j = i + 1; j < count; j++)); do
      if (( ${MODULE_IDS[j]} < ${MODULE_IDS[i]} )); then
        local tmp
        tmp=${MODULE_IDS[i]}; MODULE_IDS[i]=${MODULE_IDS[j]}; MODULE_IDS[j]=$tmp
        tmp=${MODULE_LABELS[i]}; MODULE_LABELS[i]=${MODULE_LABELS[j]}; MODULE_LABELS[j]=$tmp
        tmp=${MODULE_FUNCS[i]}; MODULE_FUNCS[i]=${MODULE_FUNCS[j]}; MODULE_FUNCS[j]=$tmp
        tmp=${MODULE_SOURCES[i]}; MODULE_SOURCES[i]=${MODULE_SOURCES[j]}; MODULE_SOURCES[j]=$tmp
      fi
    done
  done
}

# 渲染主菜单
render_main_menu() {
  if has_command clear; then
    clear
  fi
  ui_print_header "Linux Y Toolbox"
  local i idx
  for i in "${!MODULE_LABELS[@]}"; do
    idx=$((i + 1))
    printf "%d) %s\n" "$idx" "${MODULE_LABELS[i]}"
  done
  echo "0) 退出"
  echo "------------------------------------"
}

# 主循环
main_loop() {
  if [ "${#MODULE_FUNCS[@]}" -eq 0 ]; then
    ui_print_error "未找到可用模块，请检查 modules 目录。"
    exit 1
  fi

  while true; do
    render_main_menu
    read -r -p "请输入选项: " choice_raw
    local choice
    choice=$(echo "$choice_raw" | tr -d '[:space:]')
    if [ -z "$choice" ]; then
      ui_print_error "请输入数字选项。"
      continue
    fi
    if [ "$choice" = "0" ]; then
      exit 0
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
      ui_print_error "请输入有效的数字。"
      continue
    fi
    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#MODULE_FUNCS[@]}" ]; then
      local func="${MODULE_FUNCS[$index]}"
      if declare -F "$func" >/dev/null 2>&1; then
        "$func"
      else
        ui_print_error "模块函数不存在: $func"
        ui_press_enter_to_continue
      fi
    else
      ui_print_error "无效选项。"
      ui_press_enter_to_continue
    fi
  done
}

load_modules
sort_modules
main_loop
