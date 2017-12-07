#!/bin/bash -x
# vim: syn=sh:expandtab:ts=4:sw=4:

# =========================================================================== CLEANUP

if [ "$1" = "clean" ]
then
  killall vault
  rm -fr etc var #bin
  rm -f nohup.out *.token *.keys *.hcl *.crt *.key
  exit
fi

killall vault 2>/dev/null
rm -fr var/vault/

mkdir -p etc/ssl/{certs,keys} etc/vault/plugins var/vault bin

# =========================================================================== VAULT SERVER

# --------------------------------------------------------------------------- vault binary

if [ ! -f "bin/vault" ]
then
  ver="0.9.0"
  zip="vault_${ver}_linux_amd64.zip"
  url="https://releases.hashicorp.com/vault/$ver/$zip"
  curl -SL "$url" -o "$zip"
  unzip "$zip" -d "bin/"
  rm -f $zip
fi

# --------------------------------------------------------------------------- self-signed HTTPS Certificates

key="etc/ssl/keys/vault.key"
crt="etc/ssl/certs/vault.crt"
if [ ! -f "$key" ] || [ ! -f "$crt" ]
then
  openssl x509 \
    -in <(
        openssl req \
            -days 3650 \
            -newkey rsa:4096 \
            -nodes \
            -keyout "$key" \
            -subj "/C=FR/L=Paris/O=frntn/OU=DevOps/CN=vault.local"
        ) \
    -req \
    -signkey "$key" \
    -sha256 \
    -days 3650 \
    -out "$crt" \
    -extfile <(echo -e "basicConstraints=critical,CA:true,pathlen:0\nsubjectAltName=DNS:vault.rocks,IP:127.0.0.1")
fi

export VAULT_SKIP_VERIFY=true

# --------------------------------------------------------------------------- server config

cat <<EOF > etc/vault/config.hcl

storage "file" {
  path = "var/vault"
}

listener "tcp" {
  address = "127.0.0.1:8200"
 
  tls_disable = 0
  tls_cert_file = "$crt"
  tls_key_file = "$key"  
}

plugin_directory = "etc/vault/plugins"

disable_mlock = true

api_addr = "https://127.0.0.1:8200"

EOF

# --------------------------------------------------------------------------- server init/unseal/auth

sleep 1
nohup ./bin/vault server -config=etc/vault/config.hcl &
sleep 3

vault init -key-shares=1 -key-threshold=1                  \
    | tee                                                  \
    >(awk '/^Initial Root Token:/{print $4}' > root.token) \
    >(awk '/^Unseal Key/{print $4}' > unseal.keys)

vault unseal $(cat unseal.keys)

vault auth $(cat root.token)

# =========================================================================== VAULT TOKEN HELPER

# --------------------------------------------------------------------------- helper binary

mkdir -p "$HOME/.vault.d/token-helpers"

cp vault-token-helper-gopass "$HOME/.vault.d/token-helpers"

chmod +x "$HOME/.vault.d/token-helpers/vault-token-helper-gopass"

# --------------------------------------------------------------------------- helper config

tk="token_helper = \"$HOME/.vault.d/token-helpers/vault-token-helper-gopass\""
if [ -f ~/.vault ] 
then
    if grep -q ^token_helper ~/.vault
    then
        sed -e "/^token_helper/s,.*,$tk," ~/.vault
    else
       echo "$tk" >> ~/.vault
    fi
else
    echo "$tk" > ~/.vault
fi

# =========================================================================== USAGE

set +x

echo "
===========================================================================

Usage :

$ export VAULT_SKIP_VERIFY=true

$ ./bin/vault auth \$(cat root.token)

===========================================================================

"
