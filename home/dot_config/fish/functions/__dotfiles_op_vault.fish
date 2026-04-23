function __dotfiles_op_vault --description "Resolve the 1Password vault name from chezmoi data, defaulting to Private."
    # chezmoi data emits op_vault twice (once per scope tree), so `head -1` is required
    # to avoid the duplicated-value bug. tr strips both JSON quoting and trailing comma.
    set -l v (chezmoi data 2>/dev/null | grep op_vault | head -1 | awk '{print $NF}' | tr -d '",')
    test -z "$v"; and set v Private
    echo $v
end
