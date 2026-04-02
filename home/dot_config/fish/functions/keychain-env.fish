# Load a macOS Keychain secret into an env var
# Usage: keychain-env GITHUB_TOKEN "GITHUB_TOKEN"
function keychain-env --description "Load a macOS Keychain secret into an env var"
    if test (count $argv) -lt 1
        echo "Usage: keychain-env VAR_NAME [service-name]"
        return 1
    end
    set -l var_name $argv[1]
    set -l service (if test (count $argv) -ge 2; echo $argv[2]; else; echo $var_name; end)
    set -l value (security find-generic-password -a $USER -s $service -w 2>/dev/null)
    if test $status -eq 0 -a -n "$value"
        set -gx $var_name $value
        echo "loaded $var_name from Keychain"
    else
        echo "not found: '$service' in Keychain"
        return 1
    end
end
