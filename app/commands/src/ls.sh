secret_names=("Name")
path=$(secrets_context_path "secrets")
files=$(find $path -type f)

if [ -z "$files" ]; then
    warning "No secrets found." 0
fi


passphrase=$(get_passphrase_from_env_vars ${args[--passphrase]})
## if not set, use --passphrase flag
if [ -z "$passphrase" ];
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

yaml=""
namespaces=()
base=$(secrets_context_path "secrets")
for file in $(find $base -maxdepth 1 -mindepth 1 -type d); do
    # get last part of path
    namespace=$(basename $file)
    namespaces+=($namespace)
    yaml="$(echo "$yaml" | yq ".\"$namespace\" = []")"
done
as_yaml=${args[--yaml]:-0}
for namespace in ${namespaces[@]}; do
    if [  $as_yaml != 1 ]; then
       echo "$namespace namespace secrets:"
    fi
    for file in $(find $path/$namespace -type f); do
        secret=$(cat $file | openssl enc -d -a -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase)
        name=$(echo "$secret" | yq -r ".__secret_cli_name__")
        yaml=$(echo "$yaml" | yq ".$namespace += \"$name\"")
        if [  $as_yaml != 1 ]; then
            echo "  * $name"
        fi
    done
    if [  $as_yaml != 1 ]; then
        echo ""
    fi
done

if [  $as_yaml != 1 ]; then
    exit 0
fi

echo "$yaml" | yq


