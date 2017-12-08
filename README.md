# frntn/vault-token-helper-gopass

[gopass](https://www.justwatch.com/gopass/) is a password manager for teams using GPG+GIT.

[vault](https://www.vaultproject.io/) is a tool for managing secrets in modern computing environments.

From [this blog post](https://www.hashicorp.com/blog/building-a-vault-token-helper) we learn how to create a _token helper_, allowing vault not to store its tokens on the filesystem but on a more secure storage area.

An [example project](https://github.com/sethvargo/vault-token-helper-osx-keychain), by Seth Vargo, implement an helper allowing vault to store its tokens to OSX Keychain

This [project](https://github.com/frntn/vault-token-helper-gopass), implement an helper allowing vault to store its tokens to Gopass.

## Prerequisites

A properly installed gopass ( >= 1.6.2 is [required](https://github.com/justwatchcom/gopass/issues/482) )

Also, vault tokens are not meant to be shared, so the vault helper stores the token in a `private/` folder which can be a mounted store (handy if you only have 1 store setup and shared with your teams -- which may represent most gopass setup) :

```
# create a new store and mount it
gopass init --store private --path /path/to/your/new/store

# or mount an existing store
gopass mounts add private /path/to/your/exising/store
```

## Usage

Start a server and update your `~/.vault` file to use a custom token helper
```bash
$ ./demo.sh
```

Kill the demo server and cleanup folder
```bash
$ ./demo.sh clean
```

## Context

Successfully tested on Ubuntu Xenial
