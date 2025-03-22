secret_name="${args[name]}"
secret_sha=$(make_sha "$secret_name")
namespace=$(get_namespace_from_env_vars)
## use --namespace flag if given
if [ ! -z "${args[--namespace]}" ]; then
    namespace="${args[--namespace]}"
fi

if [ -z "$namespace" ]; then
    namespace="default"
fi

secret_path=$(secrets_context_path "secrets/$namespace/$secret_sha")

if [ ! -f "$secret_path" ]; then
    error "Secret with name '$secret_name' does not exist in namespace '$namespace'." 1
fi

yaml_data=$(generate_yaml_from_other_args other_args)
if [ ! -z "${args[--from - yaml]}" ]; then
    if [ -f "${args[--from - yaml]}" ]; then
        file_data=$(cat "${args[--from - yaml]}")
    else
        file_data="${args[--from - yaml]}"
    fi
    mkdir -p "$(tmp_path)"
    echo "$yaml_data" >"$(tmp_path 1.yaml)"
    echo "$file_data" >"$(tmp_path 2.yaml)"
    yaml_data="$(yq eval-all '. as $item ireduce ({}; . * $item )' "$(tmp_path 1.yaml)" "$(tmp_path 2.yaml)")"
    rm -rf "$(tmp_path)"
fi

if [ -z "$yaml_data" ]; then
    error "No update data provided for secret." 1
fi

## append a name so we know what its called when listing secrets
passphrase=$(get_passphrase_from_env_vars)

## use --passphrase flag if given
if [ ! -z "${args[--passphrase]}" ]; then
    passphrase="${args[--passphrase]}"
fi

secret_yaml_data=$(get_decrypted_secret_data "$secret_path" "$passphrase")
mkdir -p "$(tmp_path)"
echo "$secret_yaml_data" >"$(tmp_path 1.yaml)"
echo "$yaml_data" >"$(tmp_path 2.yaml)"
yaml_data="$(yq eval-all '. as $item ireduce ({}; . * $item )' "$(tmp_path 1.yaml)" "$(tmp_path 2.yaml)")"
## Remove computed keys for internal use
yaml_data="$(echo "$yaml_data" | yq 'del(.["__secret_cli_name__"])')"

rm -rf "$(tmp_path)"

preview=${args[--preview]:-0}
if [ $preview = 1 ]; then
    echo "$yaml_data" | yq
    exit 0
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

## append a name so we know what its called when listing secrets
yaml_data=$(echo "$yaml_data" | yq eval '. + {"__secret_cli_name__": "'$secret_name'"}')
secret=$(echo "$yaml_data" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase -base64)

mkdir -p "$(dirname "$secret_path")"
echo "$secret" >"$secret_path"

success "Updated secret with name '$secret_name' in namespace '$namespace'."
