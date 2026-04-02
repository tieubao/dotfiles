complete -c keychain-set -f
complete -c keychain-set -n "__fish_is_nth_token 1" -d "Service name"
complete -c keychain-set -n "__fish_is_nth_token 2" -d "Secret value"
