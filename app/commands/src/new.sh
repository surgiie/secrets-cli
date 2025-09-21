if [ -z $EDITOR ]; then
    error "No EDITOR environment variable set. Please set it to your preferred text editor."
    exit 1
fi

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

if [ -f "$secret_path" ]; then
    error "Secret with name '$secret_name' already exists in namespace '$namespace'." 1
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
rm -rf tmp_path
mkdir -p "$(tmp_path $context)"
ext="${args[--tmp-ext]}"
tmp_file=$(mktemp $(tmp_path "$context/$secret_sha.XXXXXX.$ext"))

$EDITOR "$tmp_file"

contents=$(cat "$tmp_file")

if [ -z "$contents" ]; then
    rm -f $tmp_file
    error "No contents provided." 1
fi

contents="$secret_name\n$contents"

contents=$(echo -e "$contents" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase -base64)
if [ $? -ne 0 ]; then
    error "Encryption failed" 1
fi

mkdir -p "$(dirname "$secret_path")"
echo "$contents" >"$secret_path"

success "Generated secret '$secret_name' in namespace '$namespace' in context '$context'."
rm -f $tmp_file
