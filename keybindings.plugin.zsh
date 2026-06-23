# inspired by: https://stackoverflow.com/questions/5407916/zsh-zle-shift-selection/68987551#68987551

# This script enables copy pasting, selection etc. of text as
#  you know it from editors.
#  The script executes 3 steps:
#  1. set variables to represent terminal signals (keys)
#  2. register zle widgets (functions)
#  3. bind widgets to keys (call functions on signals)
#
# To use it:
#  1. Add this file to `$ZSH_CUSTOM/plugins/keybindings`.
#  2. Make sure all the keys are defined as described below.
#     If not, use import the `zsh-selection.itermkeymap.json` in iTerm2.
#     iTerm2 > Settings > Profiles > Keys > Key Bindings > Presets > Import

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# SET VARIABLES
#
# These variables represent the terminal signals (keys). They
#   might differ for you.
# View your variables:
#  - run `$ cat`
#  - enter the key combinations
# If you are using iTerm2, you can set signals manually with:
#  - go to: iTerm2 > Settings > Profiles > Keys > Key Mappings
#  - record the keyboard shortcut
#  - select action "Send escape sequence"
#  - enter the escape sequence without leading `^[`
#
# Terminfo is a database that describes terminals.
#  It stores some of the default signals and can be accessed
#  through predefined cap names (short names).
#  You can print the existing cap names with `$ infocmp -1`.

# default in iTerm2
typeset -r KEY_LEFT=${terminfo[kcub1]:-$'^[[D'}
typeset -r KEY_RIGHT=${terminfo[kcuf1]:-$'^[[C'}
typeset -r KEY_SHIFT_UP=${terminfo[kri]:-$'^[[1;2A'}
typeset -r KEY_SHIFT_DOWN=${terminfo[kind]:-$'^[[1;2B'}
typeset -r KEY_SHIFT_RIGHT=${terminfo[kRIT]:-$'^[[1;2C'}
typeset -r KEY_SHIFT_LEFT=${terminfo[kLFT]:-$'^[[1;2D'}
typeset -r KEY_OPT_LEFT=$'^[b'
typeset -r KEY_OPT_RIGHT=$'^[f'
typeset -r KEY_CMD_LEFT=$'^[[1;9D'
typeset -r KEY_CMD_RIGHT=$'^[[1;9C'
typeset -r KEY_SHIFT_CMD_LEFT=$'^[[1;10D'
typeset -r KEY_SHIFT_CMD_RIGHT=$'^[[1;10C'
typeset -r KEY_SHIFT_CTRL_LEFT=$'^[[1;6D'
typeset -r KEY_SHIFT_CTRL_RIGHT=$'^[[1;6C'
typeset -r KEY_CTRL_D=$'\x04' # ^D
typeset -r KEY_CTRL_L=$'\x0c' # ^L

# additional default values that differ in IntelliJ shell
typeset -r KEY_SHIFT_OPT_LEFT_INTELLIJ=$'^[^[[D'
typeset -r KEY_SHIFT_OPT_RIGHT_INTELLIJ=$'^[^[[C'

# manually set in iTerm2 (omit leading ^[)
typeset -r KEY_CMD_Z='^[[122;9u'
typeset -r KEY_SHIFT_CMD_Z='^[[122;10u'
typeset -r KEY_CMD_C='^[[99;9u'
typeset -r KEY_CMD_X='^[[120;9u'
typeset -r KEY_CMD_A='^[[97;9u'
typeset -r KEY_SHIFT_OPT_LEFT=$'^[[1;4D' # this was overwritten, default was different
typeset -r KEY_SHIFT_OPT_RIGHT=$'^[[1;4C' # this was overwritten, default was different

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# DEFINE WIDGETS
#
# zle (zsh command line editor) enables you to add stuff to your
#  command line. It comes with the concept of widgets (functions)
#  that can be bound to terminal signals.
#  To create a new widget, run: `$ zle -N WIDGET_NAME FUNCTION`.
#  To list all manually created widgets, run: `$ zle -l`.
#  To list all widgets (including those from system), run: `$ zle -l -a`.


# copy selected terminal text to clipboard
zle -N widget::copy-selection
function widget::copy-selection {
    if ((REGION_ACTIVE)); then
        zle copy-region-as-kill
        printf "%s" $CUTBUFFER | pbcopy
    fi
}

# cut selected terminal text to clipboard
zle -N widget::cut-selection
function widget::cut-selection {
    if ((REGION_ACTIVE)); then
        zle kill-region
        printf "%s" $CUTBUFFER | pbcopy
    fi
}

# paste clipboard contents
zle -N widget::paste
function widget::paste {
    ((REGION_ACTIVE)) && zle kill-region
    local clip="$(pbpaste)"
    RBUFFER="${clip}${RBUFFER}"
    CURSOR=$(( CURSOR + ${#clip} ))
}

# select entire prompt
zle -N widget::select-all
# CURSOR at start so that kill-region in widget::paste deletes correctly after Cmd+A
function widget::select-all {
    MARK=${#BUFFER}
    CURSOR=0
    REGION_ACTIVE=1
}

# scrolls the screen up, in effect clearing it
zle -N widget::scroll-and-clear-screen
function widget::scroll-and-clear-screen {
    printf "\n%.0s" {1..$LINES}
    zle clear-screen
}

function widget::util-select {
    ((REGION_ACTIVE)) || zle set-mark-command
    local widget_name=$1
    shift
    zle $widget_name -- $@
}

function widget::util-unselect {
    REGION_ACTIVE=0
    local widget_name=$1
    shift
    zle $widget_name -- $@
}

function widget::util-delselect {
    if ((REGION_ACTIVE)); then
        zle kill-region
    else
        local widget_name=$1
        shift
        zle $widget_name -- $@
    fi
}

function widget::util-insertchar {
    ((REGION_ACTIVE)) && zle kill-region
    RBUFFER="${1}${RBUFFER}"
    zle forward-char
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# BIND KEYS
#
# This binds the keys (defined above) to widgets.

#                       |  key                            | widget
# --------------------- | ------------------------------- | -------------

bindkey                   $KEY_CMD_Z                        undo
bindkey                   $KEY_SHIFT_CMD_Z                  redo
bindkey                   $KEY_CMD_C                        widget::copy-selection
bindkey                   $KEY_CMD_X                        widget::cut-selection
bindkey                   $KEY_CMD_A                        widget::select-all
bindkey                   $KEY_CTRL_L                       widget::scroll-and-clear-screen

for keyname        kcap   seq                   mode        widget (

    del            kdch1  ${terminfo[kdch1]:-$'\e[3~'}  delselect    delete-char
    bspace         kbs    ${terminfo[kbs]:-$'\x7f'}     delselect    backward-delete-char

    left           kcub1  $KEY_LEFT             unselect    backward-char
    right          kcuf1  $KEY_RIGHT            unselect    forward-char

    shift-up       kri    $KEY_SHIFT_UP         select      up-line-or-history
    shift-down     kind   $KEY_SHIFT_DOWN       select      down-line-or-history
    shift-right    kRIT   $KEY_SHIFT_RIGHT      select      forward-char
    shift-left     kLFT   $KEY_SHIFT_LEFT       select      backward-char

    opt-right         x   $KEY_OPT_RIGHT        unselect    forward-word
    opt-left          x   $KEY_OPT_LEFT         unselect    backward-word
    shift-opt-right   x   $KEY_SHIFT_OPT_RIGHT  select      forward-word
    shift-opt-left    x   $KEY_SHIFT_OPT_LEFT   select      backward-word

    cmd-right         x   $KEY_CMD_RIGHT        unselect    end-of-line
    cmd-left          x   $KEY_CMD_LEFT         unselect    beginning-of-line
    shift-cmd-right   x   $KEY_SHIFT_CMD_RIGHT  select      end-of-line
    shift-cmd-left    x   $KEY_SHIFT_CMD_LEFT   select      beginning-of-line

    shift-ctrl-right  x   $KEY_SHIFT_CTRL_RIGHT select      end-of-line
    shift-ctrl-left   x   $KEY_SHIFT_CTRL_LEFT  select      beginning-of-line
  
) {
    eval "function widget::key-$keyname {
        widget::util-$mode $widget \$@
    }"
    zle -N widget::key-$keyname
    bindkey $seq widget::key-$keyname
}

# suggested by "e.nikolov", fixes autosuggest completion being 
# overridden by keybindings: to have [zsh] autosuggest [plugin
# feature] complete visible suggestions, you can assign an array
# of shell functions to the `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS` 
# variable. when these functions are triggered, they will also 
# complete any visible suggestion. Example:
export ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
    widget::key-right
    widget::key-shift-right
    widget::key-cmd-right
    widget::key-shift-cmd-right
    widget::key-shift-ctrl-right
)