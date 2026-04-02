# Store a secret in macOS Keychain
# Usage: keychain-set SERVICE_NAME secret-value
function keychain-set --description "Store a secret in macOS Keychain"
    if test (count $argv) -lt 2
        echo "Usage: keychain-set SERVICE_NAME value"
        return 1
    end
    set -l service $argv[1]
    set -l value $argv[2]
    security add-generic-password -a $USER -s $service -w $value -U 2>/dev/null
    if test $status -eq 0
        echo "stored '$service' in Keychain"
    else
        echo "failed to store '$service'"
        return 1
    end
end
