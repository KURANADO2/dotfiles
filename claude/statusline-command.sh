#!/bin/bash
# Claude Code status line — mirrors the Starship prompt (~/.config/starship.toml).
# Module order: [os] [directory] [git_branch] [git_status] [languages] [model] [ctx]
# (left prompt first, then Claude extras; time/proxy removed per user request)
# The trailing '➜' (character module) is intentionally omitted.

set -u

input=$(cat)

# Parse the JSON input once (tab-separated; safe for paths containing spaces)
IFS=$'\t' read -r cwd model context_pct worktree < <(printf '%s' "$input" | jq -r '[
  .workspace.current_dir // "",
  .model.display_name // "",
  ((.context_window.used_percentage // "") | if type == "number" then (round | tostring) else tostring end),
  .workspace.git_worktree // ""
] | @tsv')

[ -n "$cwd" ] || cwd=$PWD

# --- Colors approximating starship styles (#82AAFF ≈ 256-color 111) ---
R=$'\e[0m'
C_OS=$'\e[1;37m'           # [os] bold white
C_DIR=$'\e[1;38;5;111m'    # [directory] style = 'bold #82AAFF'
C_BRANCH=$'\e[1;35m'       # [git_branch] starship default: bold purple
C_GITST=$'\e[1;38;5;111m'  # [git_status] style = 'bold #82AAFF'
C_JAVA=$'\e[1;31m'         # starship [java] default: bold red
C_RUST=$'\e[1;31m'         # starship [rust] default: bold red
C_PY=$'\e[1;33m'           # starship [python] default: bold yellow
C_NODE=$'\e[1;32m'         # starship [nodejs] default: bold green
C_GO=$'\e[1;36m'           # starship [golang] default: bold cyan
C_MODEL=$'\e[35m'          # Claude model
C_CTX=$'\e[33m'            # context usage

parts=()

# [os] module — enabled in starship.toml; macOS symbol
parts+=("${C_OS} ${R}")

# [directory] — truncation_length = 0 / truncate_to_repo = false → full path, $HOME → ~
home_sym='~'
dir_disp="${cwd/#$HOME/$home_sym}"
parts+=("${C_DIR}${dir_disp}${R}")

# [git_branch] + [git_status] — single git call (porcelain v1 with branch header)
gitout=$(git -C "$cwd" --no-optional-locks status --porcelain=v1 -b 2>/dev/null) || gitout=""
if [ -n "$gitout" ]; then
  header=${gitout%%$'\n'*}
  ref=${header#'## '}
  branch=${ref%%...*}
  if [[ $ref == "No commits yet on "* ]]; then
    branch=${ref##* }
  elif [ "$branch" = "HEAD (no branch)" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi

  files=${gitout#*$'\n'}
  [ "$files" = "$gitout" ] && files=""

  # starship [git_status] default symbols: = conflicted, + staged, ! not staged, ✘ deleted, ? untracked
  st=""
  if [ -n "$files" ]; then
    st=$(awk '
      /^\?\?/ { u = 1; next }
      {
        x = substr($0, 1, 1); y = substr($0, 2, 1)
        if (x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D")) c = 1
        else if (x ~ /[MADRC]/) s = 1
        if (y == "M") m = 1
        if (x == "D" || y == "D") d = 1
      }
      END {
        out = ""
        if (c) out = out "="
        if (s) out = out "+"
        if (m) out = out "!"
        if (d) out = out "✘"
        if (u) out = out "?"
        printf "%s", out
      }' <<< "$files")
  fi

  # ahead/behind arrows (starship: ⇡ ahead, ⇣ behind, ⇕ diverged)
  ab=""
  if [[ $header == *"[ahead "* && $header == *"behind "* ]]; then ab="⇕"
  elif [[ $header == *"[ahead "* ]]; then ab="⇡"
  elif [[ $header == *"[behind "* ]]; then ab="⇣"
  fi

  git_part="${C_BRANCH} ${branch}${R}"
  [ -n "${st}${ab}" ] && git_part+=" ${C_GITST}[${st}${ab}]${R}"
  [ -n "$worktree" ] && git_part+=" ${C_GITST}(${worktree})${R}"
  parts+=("$git_part")
fi

# Language modules — same set as starship.toml ([java] [rust] [python] [nodejs] [golang])
if [ -f "$cwd/pom.xml" ] || [ -f "$cwd/build.gradle" ] || [ -f "$cwd/build.gradle.kts" ]; then
  java_ver=$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([^"]*\)".*/\1/p')
  case $java_ver in
    1.*) java_ver=$(printf '%s' "$java_ver" | cut -d. -f2) ;;  # legacy 1.8 → 8
    *)   java_ver=${java_ver%%.*} ;;
  esac
  [ -n "$java_ver" ] && parts+=("${C_JAVA}☕ ${java_ver}${R}")
fi
if [ -f "$cwd/Cargo.toml" ]; then
  rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
  [ -n "$rust_ver" ] && parts+=("${C_RUST}🦀 ${rust_ver}${R}")
fi
if [ -f "$cwd/requirements.txt" ] || [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/setup.py" ] || [ -d "$cwd/.venv" ]; then
  py_ver=$(python --version 2>/dev/null | awk '{print $2}')
  [ -n "$py_ver" ] && parts+=("${C_PY}🐍 ${py_ver}${R}")
fi
if [ -f "$cwd/package.json" ]; then
  node_ver=$(node --version 2>/dev/null | sed 's/^v//')
  [ -n "$node_ver" ] && parts+=("${C_NODE}⬢ ${node_ver}${R}")
fi
if [ -f "$cwd/go.mod" ]; then
  go_ver=$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')
  [ -n "$go_ver" ] && parts+=("${C_GO}🐹 ${go_ver}${R}")
fi

# Claude-specific extras: model name + context usage
[ -n "$model" ] && parts+=("${C_MODEL}${model}${R}")
[ -n "$context_pct" ] && parts+=("${C_CTX}ctx:${context_pct}%${R}")

# 时间与代理展示已按要求移除（starship 侧也已关闭，两边保持一致）

# Join parts with single spaces
line=""
for p in "${parts[@]}"; do
  if [ -z "$line" ]; then line=$p; else line="$line $p"; fi
done
printf '%s\n' "$line"