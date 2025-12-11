#!/usr/bin/env bash
# shellcheck shell=bash

# 颜色定义：在支持的终端上启用 ANSI 颜色；否则回退为空字符串
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _C_RESET='\033[0m'
  _C_BOLD='\033[1m'
  _C_RED='\033[31m'
  _C_GREEN='\033[32m'
  _C_YELLOW='\033[33m'
  _C_BLUE='\033[34m'
else
  _C_RESET=''
  _C_BOLD=''
  _C_RED=''
  _C_GREEN=''
  _C_YELLOW=''
  _C_BLUE=''
fi

# 文本样式助手
color_reset() { printf '%b' "$_C_RESET"; }
color_bold() { printf '%b%s%b' "$_C_BOLD" "$*" "$_C_RESET"; }
color_red() { printf '%b%s%b' "$_C_RED" "$*" "$_C_RESET"; }
color_green() { printf '%b%s%b' "$_C_GREEN" "$*" "$_C_RESET"; }
color_yellow() { printf '%b%s%b' "$_C_YELLOW" "$*" "$_C_RESET"; }
color_blue() { printf '%b%s%b' "$_C_BLUE" "$*" "$_C_RESET"; }
