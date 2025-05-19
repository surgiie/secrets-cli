## remove trailing character.
remove_trailing() {
    value="$1"
    char="$2"
    echo ${value%"$char"}
}
## make a sha1 hash from a string.
make_sha() {
    value="$1"
    echo -n "$value" | sha1sum | cut -d ' ' -f1
}
## Confirm a user action.
confirm() {
    echo -n "$(yellow_bold [CONFIRM]): $1 [y/n]: "
    read -r -p "" response
    [[ "$response" == [Yy] ]]
}

## Get decrypted secret data yaml
get_decrypted_secret_data() {
    secret_path="$1"
    passphrase="$2"
    yaml_data=$(cat "$secret_path" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:$passphrase -d -base64)
    echo "$yaml_data"
}

## Get namespace from environment variables
get_namespace_from_env_vars() {
    context="$(get_cli_context)"
    context=$(echo $context | tr '[:lower:]' '[:upper:]')
    context_var="SECRETS_CLI_${context}_NAMESPACE"
    namespace="${!context_var}"

    if [ -z "$namespace" ]; then
        namespace="${SECRETS_CLI_NAMESPACE:-}"
    fi
    echo $namespace
}

## Get passphrase for encryption from the environment variables
get_passphrase_from_env_vars() {
    context="$(get_cli_context)"
    context=$(echo $context | tr '[:lower:]' '[:upper:]')
    context_var="SECRETS_CLI_${context}_PASSPHRASE"
    passphrase="${!context_var}"

    if [ -z "$passphrase" ]; then
        passphrase="${SECRETS_CLI_PASSPHRASE:-}"
    fi

    echo $passphrase

}

## Parse string for yq assignment:
parse_value_for_yq_assignment() {
    value="$1"
    if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" == "null" ]]; then
        echo "$value"
    else
        echo "\"$value\""
    fi
}

## generate yaml data from other_args bashly array:
generate_yaml_from_other_args() {
    i=0
    yaml=""
    declare -n args=$1
    declare -A keys_seen # Track repeated keys
    while [ $i -lt ${#args[@]} ]; do
        raw_key="${args[i]}"
        key="${args[i]#--}"    # Remove leading "--"
        value="${args[i + 1]}" # Get the corresponding value

        # encountered a --option $p <- undefined so parses incorrectly for previous value
        if [[ -z "$key" ]]; then
            continue
        fi
        i=$((i + 2)) # Move to the next pair
        # If value is empty or another flag, treat it as a boolean "true"
        if [[ -z "$value" || "$value" =~ ^--[^-] ]]; then
            value="true"
            ((i--)) # Step back since value is actually a new key
        fi

        # Check if key already exists in YAML
        if [[ -n "${keys_seen[$key]}" ]]; then
            # Convert existing key to an array if not already one
            if [[ $(echo "$yaml" | yq ".${key} | type") != "!!seq" ]]; then
                current_value=$(echo "$yaml" | yq -r ".${key}")
                current_value=$(parse_value_for_yq_assignment "$current_value")
                yaml=$(echo "$yaml" | yq ".${key} = [$current_value]")
            fi
            value=$(parse_value_for_yq_assignment "$value")
            yaml=$(echo "$yaml" | yq ".${key} += [$value]")
        elif [[ "$raw_key" =~ ^--[^-] ]]; then
            value=$(parse_value_for_yq_assignment "$value")
            yaml=$(echo "$yaml" | yq ".${key} = $value")
            keys_seen["$key"]=1 # Mark key as seen
        fi
    done
    echo "$yaml"
}

## get the current context.
get_cli_context() {
    context="${SECRETS_CLI_CONTEXT:-default}"
    echo $context
}

## genearate a path relative to the project .secrets/context/<context> dir.
secrets_context_path() {
    path="${1:-/}"
    context="$(get_cli_context)"
    base="$HOME/.secrets/contexts/$context"
    path="$base/$path"
    echo $(remove_trailing "$path" "/")
}

## genearate a path relative to the project /tmp/.secrets dir.
tmp_path() {
    path="${1:-/}"
    base="/tmp/.secrets"
    path="$base/$path"
    echo $(remove_trailing "$path" "/")
}

## genearate a path relative to the project .secrets dir.
secrets_path() {
    path="${1:-/}"
    base="$HOME/.secrets"
    path="$base/$path"
    echo $(remove_trailing "$path" "/")
}

## generate a path relative to the root of the cli directory.
secrets_cli_path() {
    path="${1:-/}"
    base="$SECRETS_CLI_PATH"
    path="$base/$path"
    echo $(remove_trailing "$path" "/")
}
