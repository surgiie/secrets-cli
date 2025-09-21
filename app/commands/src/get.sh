context="$(get_cli_context)"
secret_name="${args[name]}"
secret_sha=$(make_sha "$secret_name")
namespace=$(get_namespace_from_env_vars)

if [ ! -z "${args[--namespace]}" ]; then
    namespace="${args[--namespace]}"
fi

if [ -z "$namespace" ]; then
    namespace="default"
fi

secret_path=$(secrets_context_path "items/$namespace/$secret_sha")

if [ ! -f "$secret_path" ]; then
    error "Secret with name '$secret_name' doesnt exist in namespace '$namespace'." 1
fi

mkdir -p "$(dirname "$secret_path")"
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

contents=$(cat "$secret_path" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase -d -base64)
## pop off first line that we stored name of item.
name=$(printf "%s" "$contents" | head -n1)
## get the rest of the content by itself without first line
contents=$(printf "%s" "$contents" | tail -n +2)

echo "$contents"
