function fish_greeting
    # Maximal rice: gradient banner generated from the wallpaper palette
    # active rice = this session's choice, else the login default
    set -l rice (cat $XDG_RUNTIME_DIR/hypr-rice 2> /dev/null)
    test -z "$rice"; and set rice (cat ~/.config/hypr/rices/default 2> /dev/null)
    if test "$rice" = maximal; and test -f ~/.config/hypr/rices/maximal/generated/greeting.txt
        cat ~/.config/hypr/rices/maximal/generated/greeting.txt
        command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
        return
    end

    echo -ne '\x1b[38;5;16m'  # Set colour to primary
    echo '     ______           __          __  _       '
    echo '    / ____/___ ____  / /__  _____/ /_(_)___ _ '
    echo '   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/ '
    echo '  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /  '
    echo '  \____/\__,_/\___/_/\___/____/\__/_/\__,_/   '
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
