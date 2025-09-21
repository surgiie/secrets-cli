# secrets-cli

Manage your secrets as AES-256 encrypted (openssl) files using your editor and a passphrase.


## Introduction

`secrets-cli` is a small wrapper around `openssl` for managing secrets using your editor (as defined in $EDITOR) and a passhprase.

## Dependencies

- openssl

## Installation

```bash
# Assumes $PATH includes $HOME/.local/bin, add or customize as needed
desired_version=0.1.0 && wget -qO $HOME/.local/bin/secrets https://raw.githubusercontent.com/surgiie/secrets-cli/refs/tags/v$desired_version/secrets && chmod u+x $HOME/.local/bin/secrets
```

## Usage

### Specify CLI Context

Optionally specify the cli context:

```bash
# specify the cli context
export SECRETS_CLI_CONTEXT=my-vault
```

**Note**: The context is simply a namespacing mechanism for managing multiple sets of secrets. If not specified, the default context is `default`.

### Create Secret
To create a new secret, run the `new` command:

```bash
secrets new my-secret-name
```

This will open your editor for you to write the content of the secret within your editor. For example, if you wanted to save some yaml data as a secret:

```yaml
mysecret: my secret data
mysecret2: my secret data 2
```

Once you close your editor session, your secret will be written automatically to your secrets directory.


# Data Location

All data is written to the `$HOME/.secrets` directory.

# Get Secret

To output secret decrypted, run the `get` command:

```bash
secrets get my-secret
```

# Update Secret

To edit and update a secreti in your editor, run the `edit` command:

```bash
secrets edit my-secret-name
```

Just as the `new` command, this command will also open your editor and once session is closed, your secret should be updated.


### List Secrets
To list out secrets run the `ls` command:

```bash
secrets ls
```

### Namespaces

Namespaces are a way to group secrets. By default, all secrets are created in the `default` namespace. To create a secret in a different namespace, use the `--namespace` option when calling commands:

```bash
# Create a secret in a different namespace
secrets new mysecret --namespace work
```

### Passphrase Input Options

By default, the passphrase is prompted for. If you need a non interactive way to provide the passphrase, use the `--passphrase` option:

```bash
# Provide the passphrase as an option
secrets get mysecret --passphrase mypassphrase
```

If you prefer not to pass the passphrase as an option, you can set one of the following environment variable:

```bash
# Context specific environment variable:
export SECRETS_CLI_<CONTEXT>_PASSPHRASE=mypassphrase # replace <CONTEXT> with the context name
# Or global environment variable
export SECRET_CLI_PASSPHRASE=mypassphrase
```
