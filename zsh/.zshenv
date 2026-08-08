export EDITOR="nvim"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--layout=reverse'
export VISUAL="nvim"
export TERM="foot"
export BROWSER="firefox"

export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

export ELECTRON_OZONE_PLATFORM_HINT=auto

# android
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# AI agents
export PATH="$HOME/.local/bin:$PATH"
