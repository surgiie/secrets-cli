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

## Confirm the removal of the secrets
if [[ ${args[--force]} != 1 ]] && ! confirm "Are you sure you want to remove '$secret_name' from your stored secrets?"; then
    warning "Aborted." 1
fi

rm -f "$secret_path"
success "Removed secret '$secret_name' in namespace '$namespace' in context '$context'."
