function op --description 'op CLI: biometric in interactive shells, SA bearer auth in subprocesses (S-49)'
    if status is-interactive
        env -u OP_SERVICE_ACCOUNT_TOKEN command op $argv
    else
        command op $argv
    end
end
