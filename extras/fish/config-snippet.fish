# Add inside `if status is-interactive` in ~/.config/fish/config.fish:
# terminal palette (and fastfetch accent slots 16-20) generated from the wallpaper / album art
set -l __rice (cat $XDG_RUNTIME_DIR/hypr-rice 2> /dev/null)
test -z "$__rice"; and set __rice (cat ~/.config/hypr/rices/default 2> /dev/null)
if test "$__rice" = maximal; and test -f ~/.config/hypr/rices/maximal/generated/sequences.txt
    cat ~/.config/hypr/rices/maximal/generated/sequences.txt
end
