#!/bin/sh
set -eu

STOCK=/etc/sv/udevd
FIX=/etc/sv/udevd-audio

has_fix() {
    grep -Eq '^[[:space:]]*udevadm[[:space:]]+trigger([[:space:]]|$)' "$STOCK/run"
}

install_fix() {
    if has_fix; then
        echo "Official udevd fix already exists. No workaround needed."
        rm -rf "$FIX"
        [ -e /var/service/udevd-audio ] && rm -f /var/service/udevd-audio
        [ -e /var/service/udevd ] || ln -s "$STOCK" /var/service/udevd
        exit 0
    fi

    rm -rf "$FIX"
    cp -a "$STOCK" "$FIX"

    # Don't reuse supervise state from the original service.
    rm -f "$FIX/supervise" "$FIX/log/supervise"

    cat > "$FIX/run" <<'EOF'
#!/bin/sh
exec 2>&1

udevadm control --exit

{
    sleep 1
    udevadm trigger
} &

exec udevd
EOF

    chmod +x "$FIX/run"

    if [ -e /var/service/udevd ]; then
        sv down udevd || true
        rm -f /var/service/udevd
    fi

    [ -e /var/service/udevd-audio ] || \
        ln -s "$FIX" /var/service/udevd-audio

    echo "udevd-audio workaround installed."
}

update_system() {
    xbps-install -Su

    if has_fix; then
        echo "Official udevd fix found. Restoring stock service."

        [ -e /var/service/udevd-audio ] && {
            sv down udevd-audio || true
            rm -f /var/service/udevd-audio
        }

        [ -e /var/service/udevd ] || ln -s "$STOCK" /var/service/udevd
        rm -rf "$FIX"

        echo "Restored to official udevd."
    else
        echo "Official fix not found. Keeping workaround."
    fi
}

case "${1:-}" in
    install)
        install_fix
        ;;
    update)
        update_system
        ;;
    *)
        echo "Usage:"
        echo "  sudo $0 install"
        echo "  sudo $0 update"
        exit 1
        ;;
esac
