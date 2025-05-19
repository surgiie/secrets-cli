## Check all the arguments are valid secret names
names_string=""
secret_names=()

## bashly args contains both flags and positional arguments, extract only the positional arguments to determine the secret names.
for opt in ${!args[@]}; do
    name="${args[$opt]}"
    if [[ ! "$opt" =~ ^-- ]]; then
        secret_names+=("$name")
    fi
done

## Check if the secret names are valid and exist
for secret_name in ${secret_names[@]}; do
    secret_sha=$(make_sha "$secret_name")
    secret_path=$(secrets_context_path "secrets/$secret_sha")
    [[ -n "$names_string" ]] && names_string+=", "
    names_string+="$secret_name"

    if [ ! -f "$secret_path" ]; then
        error "Secret with name '$secret_name' doesnt exist." 1
    fi
done

## Confirm the removal of the secrets
if [[ ${args[--force]} != 1 ]] && ! confirm "Are you sure you want to remove '$names_string' from your stored secrets?"; then
    warning "Aborted." 1
fi

for secret_name in ${args[@]}; do
    secret_sha=$(make_sha "$secret_name")
    secret_path=$(secrets_context_path "secrets/$secret_sha")
    rm -f "$secret_path"
    if [ $? -eq 0 ]; then
        success "Secret '$secret_name' removed successfully."
    else
        error "Failed to remove secret '$secret_name'."
    fi
done
