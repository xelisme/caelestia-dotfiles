local vars = require("variables")
local fn   = require("utils.functions")

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

hl.bind("Print", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/screenshot-full"), { locked = true })

hl.bind(vars.kbObsidianWs, fn.toggle("obsidian"))
