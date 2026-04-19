function tunnel-down --description 'Bring down the SPEC-012 WireGuard egress tunnel'
    set -l conf "$HOME/.wireguard/wg0-exchange.conf"
    if not test -f $conf
        echo "error: $conf not found. See trading/operations/wg-egress-tunnel-runbook.md"
        return 1
    end
    sudo wg-quick down $conf
    or return $status
    echo "egress IP:"
    curl -s --max-time 5 ifconfig.me
    echo
end
