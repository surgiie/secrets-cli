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

rm -rf tmp_path
mkdir -p "$(tmp_path $context)"
ext="${args[--tmp-ext]}"
tmp_file=$(mktemp $(tmp_path "$context/$secret_sha.XXXXXX.$ext"))
echo -e "$contents" >$tmp_file

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

success "Updated secret '$secret_name' in namespace '$namespace' in context '$context'."
rm -f $tmp_file
