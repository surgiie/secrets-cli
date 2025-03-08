secret_name="${args[name]}"
secret_sha=$(make_sha "$secret_name")
namespace=$(get_namespace_from_env_vars)
## use --namespace flag if given
if [ ! -z "${args[--namespace]}" ];
then
    namespace="${args[--namespace]}"
fi

if [ -z "$namespace" ]; then
    namespace="default"
fi

secret_path=$(secrets_context_path "secrets/$namespace/$secret_sha")

if [ ! -f "$secret_path" ]; then
    error "Secret with name '$secret_name' does not exists in namespace '$namespace'." 1
fi

passphrase=$(get_passphrase_from_env_vars)

## use --passphrase flag if given
if [ ! -z "${args[--passphrase]}" ];
then
    passphrase="${args[--passphrase]}"
fi

## If still not set, prompt user for passphrase.
if [ -z "$passphrase" ]; then
    info "Enter passphrase for encryption: "
    read -s passphrase
    info "Confirm passphrase: "
    read -s confirm_passphrase
    if [ "$passphrase" != "$confirm_passphrase" ]; then
        error "Passphrases do not match." 1
    fi
fi

yaml_data=$(get_decrypted_secret_data "$secret_path" "$passphrase")
## Remove computed keys for internal use
yaml_data="$(echo "$yaml_data" | yq 'del(.["__secret_cli_name__"])')"

if [ -z "${args[--key]}" ];
then
    echo "$yaml_data" | yq
    exit 0
fi

key="${args[--key]}"

value=$(echo "$yaml_data" | yq -r ".$key")

echo "$value"



