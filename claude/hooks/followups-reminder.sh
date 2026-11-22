#!/usr/bin/env bash
# =============================================================================
# followups-reminder.sh —— SessionStart hook：开门播报待办登记簿
#
# 新会话开始时检查本项目的待办登记簿（~/.claude/followups/<项目名>.md），
# 有未关闭条目（[open] / [handed-off(任务名)]）就把清单打印到 stdout——
# SessionStart hook 的 stdout 会注入会话上下文，会话一开门就知道欠了什么账。
# 无登记簿或无未关闭条目则完全静默。
#
# 项目名解析：cwd（hook stdin JSON 提供）在 git 仓库内 → 用
# `git rev-parse --git-common-dir` 归一到主仓库根目录的 basename
# （worktree 也算主仓库，不分裂）；不在 git 仓库 → 用 cwd 的 basename。
#
# 条目识别约定：顶格二级标题「## [状态] 日期 标题」，状态只认
# [open] / [handed-off(...)] / [done] 三种；模板注释里的缩进示例不顶格，
# 不会被误计（格式见 claude/CLAUDE.tmux.md「待办登记簿」一节）。
#
# 任何情况都 exit 0——hook 非零退出会被 claude 当作阻断/反馈信号，绝不允许。
#
# 用法（由 ~/.claude/settings.json 的 SessionStart hooks 调用，勿手动执行）：
#   echo '{"cwd":"/path/to/project",...}' | followups-reminder.sh
# =============================================================================

input="$(cat 2>/dev/null)"
cwd="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"

# ---- 解析项目名（git 仓库归一到主仓库名，worktree 场景不分裂） ----
project=""
common="$(cd "$cwd" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null)" || common=""
if [ -n "$common" ]; then
  case "$common" in
    /*) abs="$common" ;;
    *)  abs="$(cd "$cwd" && cd "$common" 2>/dev/null && pwd)" ;;
  esac
  # git-common-dir 指向主仓库的 .git 目录，去掉末尾 /.git 即仓库根
  [ -n "${abs:-}" ] && project="$(basename "$(dirname "$abs")")"
fi
[ -n "$project" ] || project="$(basename "$cwd")"

registry="${HOME}/.claude/followups/${project}.md"
[ -f "$registry" ] || exit 0

# 只播报未关闭的两种状态；无匹配（grep 退出码 1）时静默
open_lines="$(grep -E '^## \[(open|handed-off)' "$registry" 2>/dev/null)" || open_lines=""
[ -n "$open_lines" ] || exit 0

count="$(printf '%s\n' "$open_lines" | wc -l | tr -d '[:space:]')"
# 注意：变量必须写 ${var} 花括号形式——macOS 自带 bash 3.2 有多字节解析缺陷，
# $var 后紧跟全角字符会把字符首字节并入变量名扫描（展开为空且输出残缺字节）
echo "【待办登记簿】项目「${project}」有 ${count} 条未关闭待办（${registry}）："
printf '%s\n' "$open_lines" | sed 's/^## /  - /'
echo "接手修复的会话：完成并验证后请把对应条目改为 [done] 销单；本会话结论若出现「建议另起单」，必须先向登记簿追加 [open] 条目。规程见 ~/.dotfiles/claude/CLAUDE.tmux.md「待办登记簿」一节与 handoff skill"
exit 0
