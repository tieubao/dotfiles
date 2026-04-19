function tunnel-up --description 'Bring up the SPEC-012 WireGuard egress tunnel (trading / exchange whitelisting)'
    set -l conf "$HOME/.wireguard/wg0-exchange.conf"
    if not test -f $conf
        echo "error: $conf not found. See trading/operations/wg-egress-tunnel-runbook.md"
        return 1
    end
    sudo wg-quick up $conf
    or return $status
    echo "egress IP:"
    curl -s --max-time 5 ifconfig.me
    echo
end
