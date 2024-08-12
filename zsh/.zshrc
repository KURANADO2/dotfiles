# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# source some files
source ~/.zprofile 

# powerlevel10k
source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zsh-autosuggestion
# source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# starship
# eval "$(starship init zsh)"

# Alias
# ls
alias ll='ls -l'
alias l='ll'
alias la='l -a'

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
alias gclone='git clone'
alias greset='git reset'
alias gmerge='git merge'
alias gbranch='git branch'
alias gcherry='git cherry-pick'

# Lazygit
alias lg='lazygit'

# Neovim
alias vim='nvim'

# K8S
alias k='kubectl'
# 用于切换上下文配置的默认命名空间
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace'
alias kp='kubectl get pods'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kd='kubectl describe pod'

# Docker
alias d='docker'
alias dp='docker ps'
alias dpa='docker ps -a'

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

# Environment Variables
# Maven
export M2_HOME='/Users/jing/Opt/apache-maven-3.9.0'

# Java
export JDK8_HOME='/Library/Java/JavaVirtualMachines/jdk1.8.0_361.jdk/Contents/Home'
export JDK11_HOME='/Library/Java/JavaVirtualMachines/jdk-11.0.16.1.jdk/Contents/Home'
export JDK17_HOME='/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home'

export JAVA_HOME=$JDK8_HOME

alias jdk8='export JAVA_HOME=$JDK8_HOME'
alias jdk11='export JAVA_HOME=$JDK11_HOME'
alias jdk17='export JAVA_HOME=$JDK17_HOME'

# Go
export GO_HOME='/usr/local/go'

# Rust
export RUST_HOME='/Users/jing/.cargo'

# mysql-client
export MYSQL_CLIENT_HOME='/opt/homebrew/opt/mysql-client'
# Prompt
export MYSQL_PS1="\u@\h [\d]> "

# PATH
export PATH=$PATH:$M2_HOME/bin:$JAVA_HOME/bin:$GO_HOME/bin:$RUST_HOME/bin:$MYSQL_CLIENT_HOME/bin

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
