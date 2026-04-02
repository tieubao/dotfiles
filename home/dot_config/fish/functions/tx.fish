# Quick transaction lookup
# Usage: tx 0xhash [chain]
function tx --description "Look up an EVM transaction"
    if test (count $argv) -lt 1
        echo "Usage: tx 0xTXHASH [rpc-url]"
        return 1
    end
    set -l hash $argv[1]
    set -l rpc (if test (count $argv) -ge 2; echo $argv[2]; else; echo $ETH_RPC_URL; end)

    if test -z "$rpc"
        echo "Set ETH_RPC_URL or pass an RPC URL as second arg"
        return 1
    end

    echo "--- Transaction ---"
    cast tx $hash --rpc-url $rpc
    echo ""
    echo "--- Receipt ---"
    cast receipt $hash --rpc-url $rpc
end
