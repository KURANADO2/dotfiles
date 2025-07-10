# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# source some files
source ~/.zprofile

# powerlevel10k
# source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# starship
eval "$(starship init zsh)"

# autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zsh-autosuggestion
# source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh
HISTFILE=$HOME/.history
# Writes the history file sharing history command between all sessions
setopt SHARE_HISTORY
# History size
HISTSIZE=50000
SAVEHIST=50000

# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# zoxide
eval "$(zoxide init zsh)"

# Alias
# ls
alias ls='eza --hyperlink'
alias ll='ls -l --icons'
alias l='ll'
alias la='l -a'
alias lh='l -h'
alias lha='l -ha'

# cd
# alias cd='z'

# cp
alias cp='cp -i'

# mv
alias mv='mv -i'

# rm
alias rm='rm -rf'

# Tmux
alias tnew='tmux new -s'
alias ta='tmux a -t'

# Git
alias g='git'
alias ginit='git init'
alias ga='git add'
alias gs='git status -s'
alias gc='git commit'
# alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gl="git log --color --graph"
alias gt='git tag -a'
alias gfetch='git fetch'
alias gpull='git pull origin'
alias gpush='git push origin'
alias gshow='git show'
alias gcommit='git commit'
alias gadd='git add'
alias gremote='git remote'
alias gcheckout='git checkout'
alias gcb="git branch | fzf --preview 'git show --color=always {-1}' | cut -c 3- | xargs git checkout"
alias gclone='git clone'
alias greset='git reset'
alias gmerge='git merge'
alias gbranch='git branch'
alias gcherry='git cherry-pick'
alias gstash='git stash'
alias gpop='git stash pop'

# ssh
# alias ssh='kitten ssh'

# Lazygit
alias lg='lazygit'

# Lazydocker
alias ld='lazydocker'

# Neovim
alias vim='nvim'
alias v='nvim'

# K8S
alias k='kubectl'
# 用于切换上下文配置的默认命名空间
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace'
alias kp='kubectl get pods'
alias kl='kubectl logs'
alias klf='kubectl logs -f --tail=100'
alias kd='kubectl describe pod'
alias ke='kubectl exec -it'

# Docker
alias d='docker'
alias dp='docker ps'
alias dpa='docker ps -a'
alias de='docker exec -it'
alias di='docker inspect'

# Ollama
alias o='ollama'

# lazyssh
alias s='lazyssh'

# sql-param
alias sp='sql-param'

# Shadowsocks
# Enable Terminal Proxy
# alias pon='export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087;'
# Disable Terminal Proxy
# alias poff='unset http_proxy; unset https_proxy;'

# ClashX
# Enable Terminal Proxy
alias pon='export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890'
# Disable Terminal Proxy
alias poff='unset https_proxy; unset http_proxy; unset all_proxy;'

# gsed
alias sed='gsed'

# yazi
alias yi='yazi'

# pbcopy
alias pb='pbcopy'

# musicfox
alias m='musicfox'

# Environment Variables
# tldr
export TLDR_AUTO_UPDATE_DISABLED

# Maven
export M2_HOME='/Users/jing/Opt/apache-maven-3.9.0'

# Java
export JDK8_HOME='/Library/Java/JavaVirtualMachines/jdk1.8.0_361.jdk/Contents/Home'
export JDK11_HOME='/Library/Java/JavaVirtualMachines/jdk-11.jdk/Contents/Home'
export JDK17_HOME='/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home'

export JAVA_HOME=$JDK17_HOME

alias jdk8='export JAVA_HOME=$JDK8_HOME'
alias jdk11='export JAVA_HOME=$JDK11_HOME'
alias jdk17='export JAVA_HOME=$JDK17_HOME'

# Go
export GO_HOME='/usr/local/go'

# Rust
export RUST_HOME='/Users/jing/.cargo'

# mysql-client
# export MYSQL_CLIENT_HOME='/opt/homebrew/opt/mysql-client'
export MYSQL_CLIENT_HOME='/opt/homebrew/opt/mysql-client@8.4'
# Prompt
export MYSQL_PS1="\u@\h [\d]> "

export VOLTA_HOME='/Users/jing/.volta'

# PATH
export PATH=$PATH:$M2_HOME/bin:$JAVA_HOME/bin:$GO_HOME/bin:$RUST_HOME/bin:$MYSQL_CLIENT_HOME/bin:$VOLTA_HOME/bin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

# pyenv
eval "$(pyenv init - zsh)"
export PATH="$PATH:/Users/jing/.influxdb/"
