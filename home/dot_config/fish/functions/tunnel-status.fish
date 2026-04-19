function tunnel-status --description 'Check WireGuard egress tunnel state + current outbound IP'
    set -l conf "$HOME/.wireguard/wg0-exchange.conf"

    echo "=== Outbound IP ==="
    curl -s --max-time 5 ifconfig.me
    echo
    echo

    if test -f $conf
        echo "=== Configured tunnel endpoint ==="
        grep -E '^Endpoint' $conf | awk '{print $3}'
        echo
    end

    echo "=== WireGuard state (Mac) ==="
    if command -q wg
        sudo wg show 2>/dev/null; or echo "(no tunnel up or sudo required)"
    else
        echo "wg not installed; brew install wireguard-tools"
    end
end
