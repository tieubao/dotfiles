# Load web3 environment variables from 1Password on-demand
# Usage: web3_env [vault-name]
function web3_env --description "Load web3 secrets from 1Password"
    set -l vault (if test (count $argv) -ge 1; echo $argv[1]; else; echo "Developer"; end)
    echo "Loading web3 secrets from 1Password vault: $vault"
    op_env ETH_RPC_URL "op://$vault/Alchemy Mainnet/credential"
    op_env ETHERSCAN_API_KEY "op://$vault/Etherscan/api key"
    # Add more as needed:
    # op_env ARBISCAN_API_KEY "op://$vault/Arbiscan/api key"
    # op_env BASESCAN_API_KEY "op://$vault/Basescan/api key"
    echo "done"
end
