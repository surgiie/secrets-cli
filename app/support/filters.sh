## create default files in the context directory if not present.
filter_ensure_default_files() {
    context="$(get_cli_context)"
    mkdir -p $(secrets_context_path "items/")
}
