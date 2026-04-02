# R-04: Add guided age encryption setup

**Priority:** Medium
**Status:** Done
**Related:** F-09 in feature-specs.md

## Problem

Age encryption is commented out in `.chezmoi.toml.tmpl` with a 2-line comment explaining what to do. The README mentions it. But there's no guided flow, and the steps are easy to get wrong:
1. Generate key (where? what permissions?)
2. Copy public key (which line of the output?)
3. Edit the chezmoi config (uncomment the right lines, paste the key)
4. Back up the key to 1Password (what type? what title?)
5. On new machine, retrieve key before apply (but apply also creates the config... chicken-and-egg)

Without encryption, sensitive files like `~/.kube/config` or VPN configs can't be managed by chezmoi.

## Spec

Add a `dotfiles encrypt-setup` subcommand to the dotfiles fish function:

```fish
case encrypt-setup
    set -l key_path "$HOME/.config/chezmoi/key.txt"
    
    if test -f $key_path
        echo "Age key already exists at $key_path"
        echo "Public key:"
        grep "public key:" $key_path | string replace "# public key: " ""
        return 0
    end
    
    echo "Setting up age encryption for chezmoi..."
    echo ""
    
    # Step 1: Generate key
    if not command -q age-keygen
        echo "Installing age..."
        brew install age
    end
    
    mkdir -p (dirname $key_path)
    age-keygen -o $key_path 2>&1
    chmod 600 $key_path
    
    # Step 2: Extract public key
    set -l pubkey (grep "public key:" $key_path | string replace "# public key: " "")
    echo ""
    echo "Public key: $pubkey"
    echo ""
    
    # Step 3: Instruct user to update config
    echo "Next steps:"
    echo "  1. Edit chezmoi config:"
    echo "     chezmoi edit-config"
    echo ""
    echo "  2. Add these lines:"
    echo "     encryption = \"age\""
    echo "     [age]"
    echo "     identity = \"$key_path\""
    echo "     recipient = \"$pubkey\""
    echo ""
    echo "  3. Back up the key to 1Password:"
    echo "     op document create $key_path --title 'chezmoi age key' --vault=Developer"
    echo ""
    echo "  4. Add encrypted files:"
    echo "     chezmoi add --encrypt ~/.kube/config"
```

Also update the completion file to include `encrypt-setup`.

## Files to modify
- `home/dot_config/fish/functions/dotfiles.fish` (add encrypt-setup subcommand)
- `home/dot_config/fish/completions/dotfiles.fish` (add encrypt-setup to completions)

## Test
1. Run `dotfiles encrypt-setup` on machine without age key. Should generate key, print instructions.
2. Run again. Should detect existing key, print public key, exit cleanly.
3. Follow the printed instructions. Verify `chezmoi add --encrypt` works.
