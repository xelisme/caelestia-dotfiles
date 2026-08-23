# caelestia-dotfiles

Kustomisasi pribadi di atas [Caelestia](https://github.com/caelestia-dots/caelestia) (Hyprland + Quickshell). File bawaan Caelestia tidak disimpan di sini — semuanya bisa dipulihkan lewat `caelestia dots`, repo ini hanya berisi lapisan kustomisasi.

## Isi

| File | Fungsi |
|---|---|
| `config/caelestia/hypr-vars.lua` | override variabel & keybind Hyprland (browser brave, terminal kitty, SUPER+W wallpaper, SUPER+SHIFT+N pindah window ke workspace, Print → auto-save screenshot, dll) |
| `config/caelestia/hypr-user.lua` | bind tambahan: SUPER+W launcher wallpaper, Print screenshot auto-save |
| `bin/screenshot-full` | script auto-save screenshot (grim + clipboard + notif, tanpa staging cache) |
| `config/caelestia/shell.json` | setting caelestia shell |
| `config/caelestia/monitors/eDP-1/shell.json` | setting shell per-monitor |
| `config/caelestia/user-config.fish` | config fish user |
| `config/kitty/kitty.conf` | kitty: tab powerline, Alt+panah/angka navigasi tab, split Alt+D / Ctrl+Alt+panah |
| `config/swappy/config` | swappy save dir → ~/Pictures/Screenshots |
| `config/environment.d/screenshots.conf` | env var tujuan Save screenshot |

## Restore (mesin baru)

1. Pasang Arch + [caelestia-shell & caelestia-cli](https://github.com/caelestia-dots/caelestia/wiki), login sesi Hyprland
2. Jalankan `caelestia dots apply` untuk deploy base system
3. Clone repo ini, lalu:

```sh
./install.sh
```

4. Layanan tambahan yang tidak dideploy caelestia:

```sh
systemctl --user enable --now ydotool.service
```

5. Reload Hyprland (`hyprctl reload`) atau re-login.

## Catatan

- Drive penyimpanan NTFS → repo ini pakai copy-based install script, bukan symlink/stow.
- Keybind lengkap lihat `hypr-vars.lua`; alur screenshot: Print = auto-save langsung, SUPER+SHIFT+ALT+P = alur caelestia (notif Save), SUPER+SHIFT+ALT+S = region via swappy.
