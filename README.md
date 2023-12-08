# zsh-select

# inspired by: https://stackoverflow.com/questions/5407916/zsh-zle-shift-selection/68987551#68987551

This script enables copy pasting, selection etc. of text as you know it from editors.
The script executes 3 steps:
  1. set variables to represent terminal signals (keys)
  2. register zle widgets (functions)
  3. bind widgets to keys (call functions on signals)

To use it:
  1. Add this file to `$ZSH_CUSTOM/plugins/keybindings`.
  2. Make sure all the keys are defined as described below.
     If not, use import the `zsh-selection.itermkeymap.json` in iTerm2.
     iTerm2 > Settings > Profiles > Keys > Key Mappings > Presets > Import

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

## 1. SET VARIABLES

These variables represent the terminal signals (keys).
They might differ for you.
View your variables:
  - run `$ cat`
  - enter the key combinations
If you are using iTerm2, you can set signals manually with:
  - go to: iTerm2 > Settings > Profiles > Keys > Key Mappings
  - record the keyboard shortcut
  - select action "Send escape seuqence"
  - enter the escape sequence without leading `^[`

### Terminfo

Terminfo is a database that describes terminals.
It stores some of the default signals and can be accessed through predefined cap names (short names).
You can print the existing cap names with `$ infocmp -1`.


# 2. DEFINE WIDGETS

zle (zsh command line editor) enables you to add stuff to your command line.
It comes with the concept of widgets (functions) that can be bound to terminal signals.
To create a new widget, run: `$ zle -N WIDGET_NAME FUNCTION`.
To list all manually created widgets, run: `$ zle -l`.
To list all widgets (including those from system), run: `$ zle -l -a`.

# 3. BIND KEYS

Bind the keys (defined above) to widgets with `bindkey KEY WIDGET`.
