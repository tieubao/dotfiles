# Load a 1Password secret into an env var on-demand
# Usage: op_env GITHUB_TOKEN "op://Developer/GitHub Token/password"
function op_env --description "Load a 1Password secret into an env var"
    if test (count $argv) -lt 2
        echo "Usage: op_env VAR_NAME \"op://Vault/Item/Field\""
        return 1
    end
    set -l var_name $argv[1]
    set -l ref $argv[2]
    set -l value (op read $ref 2>/dev/null)
    if test $status -eq 0 -a -n "$value"
        set -gx $var_name $value
        echo "loaded $var_name"
    else
        echo "failed to read $ref — run: op signin"
        return 1
    end
end
