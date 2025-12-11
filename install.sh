#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR_DEFAULT="/opt/linux-y-toolbox"
INSTALL_DIR_FALLBACK="${HOME}/.local/share/linux-y-toolbox"
WRAPPER_PATH="/usr/local/bin/y"

log_info() { printf "\033[32m[INFO]\033[0m %s\n" "$*"; }
log_warn() { printf "\033[33m[WARN]\033[0m %s\n" "$*"; }
log_error() { printf "\033[31m[ERROR]\033[0m %s\n" "$*"; }

ensure_bash_available() {
  if ! /usr/bin/env bash -c 'exit 0' >/dev/null 2>&1; then
    log_error "未检测到 /usr/bin/env bash，请确认系统已安装 Bash。"
    exit 1
  fi
}

determine_install_dir() {
  if mkdir -p "$INSTALL_DIR_DEFAULT" >/dev/null 2>&1; then
    echo "$INSTALL_DIR_DEFAULT"
    return
  fi
  log_warn "无法写入 $INSTALL_DIR_DEFAULT，使用用户目录安装。"
  mkdir -p "$INSTALL_DIR_FALLBACK"
  echo "$INSTALL_DIR_FALLBACK"
}

confirm_overwrite() {
  local dir="$1"
  if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
    read -r -p "安装目录 $dir 已存在，是否覆盖? [y/N]: " ans
    case "${ans,,}" in
      y|yes) return 0 ;;
      *) log_warn "用户取消安装。"; exit 0 ;;
    esac
  fi
}

copy_project_files() {
  local dest="$1"
  if [ "$SCRIPT_DIR" = "$dest" ]; then
    log_info "源路径与目标路径相同，无需复制。"
    return
  fi
  rm -rf "$dest"
  mkdir -p "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$SCRIPT_DIR"/ "$dest"/
  else
    cp -a "$SCRIPT_DIR"/. "$dest"/
  fi
  chmod +x "$dest/y.sh" "$dest/install.sh"
  find "$dest/modules" -type f -name "*.sh" ! -name "*.example" -exec chmod +x {} +
}

create_wrapper() {
  local dest="$1"
  local content
  content=$(cat <<'EOF'
#!/usr/bin/env bash
TOOLBOX_DIR="${TOOLBOX_DIR:-__REPLACE__}"
exec "$TOOLBOX_DIR/y.sh" "$@"
EOF
)
  content="${content/__REPLACE__/$dest}"

  if mkdir -p "$(dirname "$WRAPPER_PATH")" >/dev/null 2>&1 && echo "$content" > "$WRAPPER_PATH" 2>/dev/null; then
    chmod +x "$WRAPPER_PATH"
    log_info "已创建可执行命令: $WRAPPER_PATH"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    if printf "%s" "$content" | sudo tee "$WRAPPER_PATH" >/dev/null; then
      sudo chmod +x "$WRAPPER_PATH"
      log_info "已使用 sudo 创建命令: $WRAPPER_PATH"
      return 0
    fi
  fi

  return 1
}

add_shell_alias() {
  local dest="$1"
  local shell_rc=""
  if [ -n "${SHELL:-}" ]; then
    case "$SHELL" in
      *zsh) shell_rc="$HOME/.zshrc" ;;
      *bash) shell_rc="$HOME/.bashrc" ;;
    esac
  fi
  if [ -z "$shell_rc" ]; then
    shell_rc="$HOME/.bashrc"
  fi

  local alias_line="alias y='bash \"$dest/y.sh\"'"
  if [ -f "$shell_rc" ] && grep -Fq "$alias_line" "$shell_rc"; then
    log_info "检测到已有 alias 配置于 $shell_rc"
  else
    {
      echo ""
      echo "# Linux Y Toolbox"
      echo "$alias_line"
    } >> "$shell_rc"
    log_info "已在 $shell_rc 中添加 alias，请重新打开终端或执行: source \"$shell_rc\""
  fi
}

main() {
  ensure_bash_available
  local install_dir
  install_dir=$(determine_install_dir)
  log_info "安装目录: $install_dir"
  confirm_overwrite "$install_dir"
  copy_project_files "$install_dir"

  if create_wrapper "$install_dir"; then
    log_info "安装完成，重新打开终端后可直接运行: y"
  else
    log_warn "无法创建 /usr/local/bin/y，将使用 alias 方式。"
    add_shell_alias "$install_dir"
    log_info "安装完成，执行: source ~/.bashrc 或重新打开终端后可使用 y"
  fi

  if [ ! -f "$install_dir/y.sh" ]; then
    log_error "安装失败，未找到 y.sh。"
    exit 1
  fi
}

main "$@"
