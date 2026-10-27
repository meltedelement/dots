# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

# Eza aliases
alias ls='eza --icons'
alias la='eza -la --icons'
alias ll='eza -l --icons'

# Copy current working directory to clipboard
cwd() {
    pwd | tr -d '\n' | wl-copy
    echo "Copied: $(pwd)"
}

unset rc
export PATH="$HOME/.npm-global/bin:$HOME/.cargo/bin:$PATH"
export TERM=xterm-256color
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/meltedelement/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/meltedelement/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/meltedelement/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/meltedelement/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# Run a command in a new kitty window (stays open after it exits), e.g. `new python example.py`
new() { setsid -f kitty --hold "$@" >/dev/null 2>&1; }
