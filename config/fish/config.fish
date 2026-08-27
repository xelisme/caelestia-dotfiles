if status is-interactive
    # Starship custom prompt
    command -v starship &> /dev/null && starship init fish | source

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    command -v eza &> /dev/null && alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # Custom colours
    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Custom fish config
    set -q XDG_CONFIG_HOME && set -l cConf $XDG_CONFIG_HOME/caelestia || set -l cConf $HOME/.config/caelestia
    source $cConf/user-config.fish 2> /dev/null
end

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"

# strix
fish_add_path /home/nyaw/.strix/bin

# perl vendor binaries (exiftool, etc.)
fish_add_path /usr/bin/vendor_perl

# Strix — LLM via 9Router
set -gx STRIX_LLM "openai/cv/nemotron-3-ultra-free"
set -gx LLM_API_BASE "http://localhost:20128/v1"
if test -f "$HOME/.strix/.llm_key"
    set -gx LLM_API_KEY (cat "$HOME/.strix/.llm_key")
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/nyaw/miniconda3/bin/conda
    eval /home/nyaw/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/nyaw/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/nyaw/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/nyaw/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

