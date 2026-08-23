local vars = require("variables")

hl.bind(
    vars.kbWallpaper,
    hl.dsp.exec_cmd(
        'if [ "$(qs -c caelestia ipc call drawers isOpen launcher)" != "1" ]; then '
            .. "qs -c caelestia ipc call drawers toggle launcher; "
            .. "sleep 0.3; "
            .. 'ydotool type ">wallpaper "; '
            .. "fi"
    )
)
