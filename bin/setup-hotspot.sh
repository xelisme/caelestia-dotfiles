#!/bin/bash
set -euo pipefail

# ============================================================================
# setup-hotspot.sh — Hotspot NAT/FORWARD installer untuk CachyOS/Arch
# ----------------------------------------------------------------------------
# Memecahkan "client hotspot connected tapi no internet" (drop 1-2 Mbps sembuh)
# dengan meng-install rule iptables yang benar + unit systemd anti-overwrite.
#
# Masalah yang diselesaikan:
#   1. FORWARD policy DROP (controller: Docker + Tailscale) membuang paket
#      client hotspot (10.42.0.0/24) -> "connected, no internet".
#   2. Kurangnya MASQUERADE untuk subnet hotspot -> NAT tidak jalan.
#   3. Docker/Tailscale menulis ulang iptables di boot -> rule hilang,
#      masalah kambuh; solusi: unit systemd hotspot-fix re-apply di akhir boot.
#
# Prasyarat: internet UPLINK via ethernet (interface non-WiFi), dan WiFi
# dipakai sebagai AP (mode shared di NetworkManager).
# ============================================================================

NC='\e[0m'; RED='\e[31m'; GRN='\e[32m'; YEL='\e[33m'; CYN='\e[36m'
say()  { printf "${CYN}::${NC} %s\n" "$*"; }
ok()   { printf "${GRN}ok${NC}  %s\n" "$*"; }
warn() { printf "${YEL}!!${NC} %s\n" "$*"; }
die()  { printf "${RED}XX${NC} %s\n" "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "jalankan sebagai root: sudo $0"

# --- deteksi interface -------------------------------------------------------
get_uplink() {
    # prefer ethernet (non-wifi) sebagai uplink internet
    for iface in /sys/class/net/*; do
        i="$(basename "$iface")"
        [ "$i" = "lo" ] && continue
        [ -d "/sys/class/net/$i/wireless" ] && continue          # skip wifi (dipakai AP)
        [ -f "/sys/class/net/$i/operstate" ] || continue
        [ "$(cat "/sys/class/net/$i/operstate")" = "up" ] || continue
        [ -f "/sys/class/net/$i/address" ] || continue
        printf '%s\n' "$i"
        return 0
    done
    return 1
}

get_wifi_ap() {
    for iface in /sys/class/net/*; do
        i="$(basename "$iface")"
        [ -d "/sys/class/net/$i/wireless" ] || continue
        mode="$(iw dev "$i" info 2>/dev/null | awk '/type/{print $2}')"
        [ "$mode" = "AP" ] && { printf '%s\n' "$i"; return 0; }
    done
    return 1
}

# --- pemilihan ---------------------------------------------------------------
say "Deteksi interface jaringan..."

UPLINK="${UPLINK:-}"
AP_IFACE="${AP_IFACE:-}"
SUBNET="${SUBNET:-10.42.0.0/24}"

if [ -z "$UPLINK" ]; then
    UPLINK="$(get_uplink)" && ok "uplink eth: $UPLINK" || warn "tidak ada uplink ethernet UP terdeteksi"
fi

if [ -z "$AP_IFACE" ]; then
    AP_IFACE="$(get_wifi_ap)" && ok "hotspot AP : $AP_IFACE" || warn "tidak ada interface WiFi ber-mode AP aktif"
fi

if [ -z "$UPLINK" ] || [ -z "$AP_IFACE" ]; then
    echo
    warn "Tidak semua interface terdeteksi otomatis. Isi manual lewat env:"
    warn "  UPLINK=<iface-eth> AP_IFACE=<iface-wifi-ap> SUBnet=<net/cidr> sudo $0"
    echo
    read -rp "UPLINK (interface internet, mis. enp3s0f3u2c2): " UPLINK
    read -rp "AP_IFACE (interface hotspot, mis. wlan0): " AP_IFACE
    [ -n "$UPLINK" ] && [ -n "$AP_IFACE" ] || die "interface tidak lengkap"
fi

# konfirmasi
echo
printf "  Uplink internet : ${CYN}%s${NC}\n" "$UPLINK"
printf "  Hotspot AP      : ${CYN}%s${NC}\n" "$AP_IFACE"
printf "  Subnet hotspot  : ${CYN}%s${NC}\n" "$SUBNET"
read -rp "Lanjut? [y/N] " yn

case "$yn" in y|Y|yes|YES) ;; *) die "dibatalkan" ;; esac

RULE_FILE="/etc/iptables/iptables.rules"

# --- 1. MASQUERADE untuk subnet hotspot -------------------------------------
say "MASQUERADE subnet hotspot ($SUBNET -> $UPLINK)..."
# idempotent: cek dulu supaya tidak dobel di run berikutnya
if ! iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE
    ok "  + MASQUERADE $SUBNET -> $UPLINK"
else
    ok "  = sudah ada"
fi

# --- 2. FORWARD ACCEPT untuk client hotspot (di atas ts-forward/DOCKER) ------
say "FORWARD ACCEPT client hotspot (di atas Tailscale/Docker chain)..."
# urutan penting: sisipkan di posisi 1-2 agar menang atas ts-forward/DOCKER-FORWARD
iptables -I FORWARD 1 -i "$AP_IFACE" -o "$UPLINK" -j ACCEPT 2>/dev/null || true
iptables -I FORWARD 1 -i "$UPLINK"   -o "$AP_IFACE" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -s "$SUBNET" 2>/dev/null || true   # hapus duplikat lama bila ada
iptables -I FORWARD 1 -s "$SUBNET" -j ACCEPT
iptables -I FORWARD 1 -d "$SUBNET" -j ACCEPT
ok "  + FORWARD ACCEPT $SUBNET / $AP_IFACE <-> $UPLINK"

# --- 3. persistence + unit systemd anti-overwrite ---------------------------
say "Menyimpan rule ke $RULE_FILE..."
mkdir -p "$(dirname "$RULE_FILE")"
iptables-save > "$RULE_FILE"
ok "  tersimpan"

say "Membuat unit systemd hotspot-fix (auto re-apply setelah Docker/Tailscale)..."
cat > /etc/systemd/system/hotspot-fix.service <<EOF
[Unit]
Description=Re-apply hotspot NAT/FORWARD rules after Docker/Tailscale
After=network.target NetworkManager.service docker.service tailscaled.service
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/iptables-restore $RULE_FILE
ExecStart=/usr/sbin/iptables -I FORWARD 1 -i $AP_IFACE -o $UPLINK -j ACCEPT
ExecStart=/usr/sbin/iptables -I FORWARD 1 -i $UPLINK -o $AP_IFACE -j ACCEPT
ExecStart=/usr/sbin/iptables -t nat -A POSTROUTING -s $SUBNET -o $UPLINK -j MASQUERADE

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now hotspot-fix >/dev/null 2>&1 || systemctl enable hotspot-fix >/dev/null
ok "  hotspot-fix.service aktif"

echo
say "Selesai. Client hotspot kini bisa akses internet (bukan lagi connected-no-internet)."
echo "  - Natik perangkat client ke SSID hotspot Anda; jika belum ada, buat via:"
echo "      nmcli con up <nama-profil-ap>   (profil mode 'ap' + ipv4.method shared)"
echo "  - Cek live: sudo iptables -t nat -L POSTROUTING -n -v | grep $SUBNET"
echo "  - Jika setelah reboot drop lagi: sudo systemctl restart hotspot-fix"
