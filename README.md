# secrets-cli

Manage your secrets as AES-256 encrypted (openssl) yaml files using command line options for data.


## Introduction

`secrets-cli` is a small wrapper around `yq` and `openssl` for managing secrets in yaml files using simple command line options for data.

## Dependencies

- yq
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

### Creating Secrets

#### Via Command Line Options
```bash

# Create a new secret
secrets new mysecret --mysecret "my secret data" --mysecret2 "my secret data 2" --name "Rick" --name "Morty" --is-sensitive
```
- The above command will create an encrypted yaml file named `mysecret` that when decrypted will look like:

```yaml
mysecret: my secret data
mysecret2: my secret data 2
name:
  - Rick
  - Morty
is-sensitive: true
```

### Command Line Options Usage/Reference

The following command line options formats are supported:

- `--key value` : for simple key value pairs. When repeated, the values are appended and converted to an array in the yaml file.
- `--key` : for boolean true values

**Note** For more complex yaml structures, see the following from yaml section.

#### Via YAML String or File
To create a new secret from existing yaml string or file (which is recommended for complex yaml structures not supported by the command line options):

```bash
# Create a new secret from yaml string

yaml='mysecret: my secret data'

secrets new --from-yaml "$yaml"

# Create a new secret from yaml file
echo $yaml > mysecret.yaml
secrets new --from-yaml mysecret.yaml
```

**Note**: The `--from-yaml` can be combined with other command line options to add more key value pairs to the yaml file. Yaml data will be merged.


#### Dry Run / Preview Yaml

To preview the yaml that will be created without actually creating, use the `--preview` option:

```bash
# Dry run / preview yaml
secrets new mysecret --mysecret "my secret data" --mysecret2 "my secret --preview
```

This is useful for piping the output to a file or another command if needed for further processing.

### Get & Output Secrets

To get and output secrets:

```bash
# Get and output secrets
secrets get mysecret
```
This will output the entire yaml file with `yq` for the secret `mysecret`.

To get and output a specific key from the secret, use the `--key` option:

```bash
# Get and output a specific key from the secret
secrets get mysecret --key specific-key
```

This will output only the value of the key `specific-key` from the secret `mysecret`

### Remove Secrets

To remove a secret:

```bash
# Remove a secret
secrets rm mysecret
```
### Update Secrets

To update a secret:

```bash

# Update a secret
secrets edit mysecret --new-secret "new secret example"
```

Data will be merged with the existing yaml file.

Like the `new` command, you can use the `--from-yaml` option to update the secret with yaml data.


### List Secrets

To list all secrets:

```bash
# List all secrets
secrets ls
```

By default, secrets are listed in a plain list text format. If you prefer to get the secrets in yaml format, use the `--yaml` option:

```bash

# List all secrets in yaml format
secrets ls --yaml
```

Secrets are listed in yaml format with the following structure:

```yaml

namespace:
    - secret1
    - secret2
    - secret3
other-namespace:
    - secret1
    - secret2
    - secret3
```

### Namespaces

Namespaces are a way to group secrets. By default, all secrets are created in the `default` namespace. To create a secret in a different namespace, use the `--namespace` option when calling commands:

```bash
# Create a secret in a different namespace
secrets new mysecret --mysecret "my secret data" --namespace work
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
