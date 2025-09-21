context="$(get_cli_context)"
secret_name="${args[name]}"
secret_sha=$(make_sha "$secret_name")

namespace=""
if [ ! -z "${args[--namespace]}" ]; then
    namespace="${args[--namespace]}"
fi

declare -A secrets
passphrase=$(get_passphrase_from_env_vars)

if [ ! -z "${args[--passphrase]}" ]; then
    passphrase="${args[--passphrase]}"
fi

if [ -z "$passphrase" ]; then
    info "Enter passphrase for encryption: "
    read -s passphrase
    info "Confirm passphrase: "
    read -s confirm_passphrase
    if [ "$passphrase" != "$confirm_passphrase" ]; then
        error "Passphrases do not match." 1
    fi
fi
if [ ! -z "$namespace" ]; then
    secrets_path=$(secrets_context_path "items/$namespace")
else
    secrets_path=$(secrets_context_path "items")
fi

encrypter="$HOME/dotfiles/common/lib/docker/encrypt-cli/docker"

for file in $(find "$secrets_path" -type f); do
    namespace="$(basename $(dirname $file))"

    contents=$(cat "$file" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase -d -base64)

    if [ $? -ne 0 ]; then
        error "Decryption failed: $contents" 1
    fi

    item_name=$(printf "%s" "$contents" | head -n1)

    if [[ -z ${secrets[$namespace]+_} ]]; then
        secrets[$namespace]=""
    fi

    secrets[$namespace]="${secrets[$namespace]} $item_name"
done

if [ ${#secrets[@]} -eq 0 ]; then
    warning "No secret items found in context '$(green_bold $context)'." 1
fi
info "Vault items in context '$(green_bold $context)':"
for ns in "${!secrets[@]}"; do
    echo "$(green_bold $ns) namespace items:"
    for item in ${secrets[$ns]}; do
        echo "  - $item"
    done
done
