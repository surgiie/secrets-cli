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
