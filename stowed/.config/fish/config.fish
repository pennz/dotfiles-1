set -gx NPM_PACKAGES "$HOME/.npm-packages"
set -gx JANET_PATH ~/.cache/janet
set -gx NODE_PATH "$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
set -gx PATH ~/bin ~/npm-packages/bin ~/.cargo/bin ~/.luarocks/bin ~/.local/bin $PATH
set -gx DISPLAY :0
set -gx LOCALE_ARCHIVE (nix-build '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive # fix locale prolem for nix pkgs, reference https://unix.stackexchange.com/questions/187402/nix-package-manager-perl-warning-setting-locale-failed

mkdir -p ~/bin $NPM_PACKAGES/bin ~/.cargo/bin ~/.luarocks/bin $JANET_PATH

set -gx fish_greeting ""
set -gx BROWSER firefox

if type -q direnv
  eval (direnv hook fish)
end

if type -q nvim
  set -gx EDITOR nvim
  set -gx VISUAL nvim
  set -gx MANPAGER "nvim +Man! -c ':set signcolumn='"
  alias vimdiff="nvim -d"
end

if locale -a | grep -q en_GB.UTF-8
  set -gx LANG en_GB.UTF-8
end

set -gx FZF_DEFAULT_COMMAND "rg --files --hidden --follow -g \"!.git/\" 2> /dev/null"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# Other git aliases are in git config
alias g="git"
alias gg="g a .; and g c -a"
alias lg="lazygit"

# Start an SSH agent if required, if not, connect to it.
initialise_ssh_agent

# Settings {{{
  set fish_greeting
  set -U  fish_user_paths            /usr/local/opt/openssl/bin $HOME/bin $HOME/.fzf/bin # $HOME/.asdf/shims $HOME/.asdf/bin 
  set -gx FZF_DEFAULT_OPTS           '--height=50% --min-height=15 --reverse'
  set -gx FZF_DEFAULT_COMMAND        'rg --files --no-ignore-vcs --hidden'
  set -gx FZF_CTRL_T_COMMAND         $FZF_DEFAULT_COMMAND
  set -gx EVENT_NOKQUEUE             1
  set -gx EDITOR                     nvim
  set -gx HOMEBREW_FORCE_VENDOR_RUBY 1
  set -gx GPG_TTY                    (tty)
  set -gx QT_QPA_PLATFORM_PLUGIN_PATH /usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/
  set -gx PYTHON_KEYRING_BACKEND     keyring.backends.null.Keyring
# }}}

# Abbreviations {{{
  # gpg-agent
  abbr gpg-add "echo | gpg -s >/dev/null ^&1"

  # config files
  abbr aa  "$EDITOR ~/.config/alacritty/alacritty.yml"
  abbr vv  "$EDITOR ~/.vimrc_back"
  abbr tt  "$EDITOR ~/.tmux.conf"
  abbr zz  "$EDITOR ~/.config/fish/config.fish"
  abbr ff  "$EDITOR ~/.config/fish/config.fish"
  abbr f5  "source  ~/.config/fish/config.fish"
  abbr zx  ". ~/.config/fish/config.fish"
  abbr ks  "kp --tcp"

  # git
  abbr g   'git '
  abbr gc  'git commit --no-gpg-sign -s -m'
  abbr gcg 'git commit -S -m'
  abbr gco 'git checkout'
  abbr ggo 'git checkout (git branch | grep -v "^*" | sed -E "s/^ +//" | fzf)'
  abbr gd  'git diff'
  abbr gl  'git log'
  abbr gp  'git push'
  abbr gpl 'git pull'
  abbr gg  'git commit -asm "Good Game" && git push'
  abbr gs  'git stash'
  abbr gsp 'git stash pop'

  # vim / vim-isms
  abbr v   "$EDITOR"
  abbr vip "$EDITOR +PlugInstall +qall"
  abbr vup "$EDITOR +PlugUpdate"
  abbr vcp "$EDITOR +PlugClean +qall"
  abbr :q  "exit"
  abbr :Q  "exit"

  # utils
  abbr ll	'tree -rt -L 1 -a -x -p -h -i -f -D' 
  abbr t	'tmux attach -d'
  abbr tat	'tmux attach -d -t'
  abbr tlw	'tmux list-windows'
  abbr tlp	'tmux list-panes'
  abbr p	'popd'
  abbr c	'pushd'
  abbr cc	'pushd -'
  abbr antlr4	'java org.antlr.v4.Tool'
  abbr grun	'java org.antlr.v4.gui.TestRig'
  abbr ss	'eval (ssh-agent -s | sed "s/\([^=]*\)=\([^;]*\)/set \1 \2/"); and ssh-add ~/.ssh/id_rsa'
  abbr nv	'nix-env'
  abbr setproxy "eval \"set -gx HTTP_PROXY $PROXY_URL; set -gx HTTPS_PROXY $PROXY_URL; set -gx http_proxy $PROXY_URL; set -gx https_proxy	$PROXY_URL; echo $PROXY_URL\""
  abbr unsetproxy 'set -gx http_proxy  ; set -gx https_proxy  ;set -gx HTTP_PROXY  ; set -gx HTTPS_PROXY	 '
  #abbr ccc	"bash $HOME/bin/ccc"
  abbr gdrive	'gdrive  --service-account go-2-learn-00c8bf796e90.json'
  abbr b     "NO_FISH=1 bash"
# }}}

# Utility functions {{{
  function kp --description "Kill processes"
    set -l __kp__pid ''
    set __kp__pid (ps -ef | sed 1d | eval "fzf $FZF_DEFAULT_OPTS -m --header='[kill:process]'" | awk '{print $2}')

    if test "x$__kp__pid" != "x"
      if test "x$argv[1]" != "x"
        echo $__kp__pid | xargs kill $argv[1]
      else
        echo $__kp__pid | xargs kill -9
      end
      kp
    end
  end

  function gcb --description "Delete git branches"
    set delete_mode '-d'

    if contains -- '--force' $argv
      set force_label ':force'
      set delete_mode '-D'
    end

    set -l branches_to_delete (git branch | sed -E 's/^[* ] //g' | fzf -m --header="[git:branch:delete$force_label]")

    if test -n "$branches_to_delete"
      git branch $delete_mode $branches_to_delete
    end
  end

  function bip --description "Install brew plugins"
    set -l inst (brew search | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:install]'")

    if not test (count $inst) = 0
      for prog in $inst
        brew install "$prog"
      end
    end
  end

  function bup --description "Update brew plugins"
    set -l inst (brew leaves | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:update]'")

    if not test (count $inst) = 0
      for prog in $inst
        brew upgrade "$prog"
      end
    end
  end

  function bcp --description "Remove brew plugins"
    set -l inst (brew leaves | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:uninstall]'")

    if not test (count $inst) = 0
      for prog in $inst
        brew uninstall "$prog"
      end
    end
  end

  function fish_prompt --description 'Write out the prompt'
    switch $status
      case 0   ; set_color green
      case 127 ; set_color yellow
      case '*' ; set_color red
    end

    set_color -od
    echo -n '• '
    set_color blue
    echo -n (prompt_pwd)

    if test (git rev-parse --git-dir 2>/dev/null)
      set_color yellow
      echo -n " on "
      set_color green
      echo -n (git status | head -1 | string split ' ')[-1]

      if test -n (echo (git status -s))
        set_color magenta
      end

      echo -n ' ⚑'
    end

    set_color yellow
    echo ' ❯ '
    set_color -normal
  end
# }}}

# Gpg {{{
  gpg-agent --daemon --no-grab >/dev/null ^&1
# }}}

# Sourcing {{{
  # macOS homebrew installs into /usr/local/share, apt uses /usr/share
  [ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish
  [ -f /usr/share/autojump/autojump.fish ]; and source /usr/share/autojump/autojump.fish
  [ -f $HOME/.nix-profile/share/autojump/autojump.fish ]; and source $HOME/.nix-profile/share/autojump/autojump.fish

  # asdf on macOS installed via homebrew, on linux via a git clone
  [ -f /usr/local/opt/asdf/asdf/asdf.fish ]; and source /usr/local/opt/asdf/asdf.fish
  [ -f $HOME/.asdf/asdf.fish ]; and source $HOME/.asdf/asdf.fish
  # if test -d $HOME/.nix-profile -a -f $HOME/.config/fish/nix.fish ; and test -d /nix
  #    source $HOME/.config/fish/nix.fish
  # end
# }}}

# TMUX {{{
#if status --is-interactive
#and command -s tmux >/dev/null
#and not set -q TMUX
#  exec tmux new -A -s (whoami) # 24301
#end
# }}}

[ -d $HOME/miniconda3 ]; and set conda_path $HOME/miniconda3
[ -d $HOME/anaconda3 ]; and set conda_path $HOME/anaconda3
[ -d /opt/conda ]; and set conda_path /opt/conda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
set -gx CONDA_EXE "$conda_path/bin/conda"
set _CONDA_ROOT "$conda_path"
set _CONDA_EXE "$conda_path/bin/conda"
# Copyright (C) 2012 Anaconda, Inc
# SPDX-License-Identifier: BSD-3-Clause
#
# INSTALL
#
#     Run 'conda init fish' and restart your shell.
#

if not set -q CONDA_SHLVL
    set -gx CONDA_SHLVL "0"
    set -g _CONDA_ROOT (dirname (dirname $CONDA_EXE))
    set -gx PATH $_CONDA_ROOT/condabin $PATH
end

function __conda_add_prompt
  if set -q CONDA_DEFAULT_ENV
      set_color normal
      echo -n '('
      set_color -o green
      echo -n $CONDA_DEFAULT_ENV
      set_color normal
      echo -n ') '
  end
end

function return_last_status
  return $argv
end

function conda --inherit-variable CONDA_EXE
    if [ (count $argv) -lt 1 ]
        eval $CONDA_EXE
    else
        set -l cmd $argv[1]
        set -e argv[1]
        switch $cmd
            case activate deactivate
                eval (eval $CONDA_EXE shell.fish $cmd $argv)
            case install update upgrade remove uninstall
                eval $CONDA_EXE $cmd $argv
                and eval (eval $CONDA_EXE shell.fish reactivate)
            case '*'
                eval $CONDA_EXE $cmd $argv
        end
    end
end




# Autocompletions below


# Faster but less tested (?)
function __fish_conda_commands
  string replace -r '.*_([a-z]+)\.py$' '$1' $_CONDA_ROOT/lib/python*/site-packages/conda/cli/main_*.py
  for f in $_CONDA_ROOT/bin/conda-*
    if test -x "$f" -a ! -d "$f"
      string replace -r '^.*/conda-' '' "$f"
    end
  end
  echo activate
  echo deactivate
end

function __fish_conda_env_commands
  string replace -r '.*_([a-z]+)\.py$' '$1' $_CONDA_ROOT/lib/python*/site-packages/conda_env/cli/main_*.py
end

function __fish_conda_envs
  conda config --json --show envs_dirs | python -c "import json, os, sys; from os.path import isdir, join; print('\n'.join(d for ed in json.load(sys.stdin)['envs_dirs'] if isdir(ed) for d in os.listdir(ed) if isdir(join(ed, d))))"
end

function __fish_conda_packages
  conda list | awk 'NR > 3 {print $1}'
end

function __fish_conda_needs_command
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 -a $cmd[1] = 'conda' ]
    return 0
  end
  return 1
end

function __fish_conda_using_command
  set cmd (commandline -opc)
  if [ (count $cmd) -gt 1 ]
    if [ $argv[1] = $cmd[2] ]
      return 0
    end
  end
  return 1
end

# Conda commands
complete -f -c conda -n '__fish_conda_needs_command' -a '(__fish_conda_commands)'
complete -f -c conda -n '__fish_conda_using_command env' -a '(__fish_conda_env_commands)'

# Commands that need environment as parameter
complete -f -c conda -n '__fish_conda_using_command activate' -a '(__fish_conda_envs)'

# Commands that need package as parameter
complete -f -c conda -n '__fish_conda_using_command remove' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command uninstall' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command upgrade' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command update' -a '(__fish_conda_packages)'

set -gx PATH (conda info | sed -n 's/.*active env location : //p')/bin $PATH
# <<< conda initialize <<<
# Local config.
if [ -f ~/.local.fish ]
  source ~/.local.fish
end
