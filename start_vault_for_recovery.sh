#!/usr/bin/bash

## Install Vault with Raft in K8s
kubectl create ns vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault --namespace vault --set server.image.tag=1.12.2,server.ha.enabled=true,server.ha.raft.enabled=true,server.ha.replicas=1 hashicorp/vault
sleep 60

## Expose the Vault service
kubectl -n vault port-forward service/vault 8200:8200 &
## Export the vault address
export VAULT_ADDR=http://127.0.0.1:8200

## Initialize and Unseal Vault
kubectl -n vault exec vault-0 -- vault operator init -format=json -key-shares=1 -key-threshold=1 > /tmp/vault-keys.json
export VAULT_TOKEN=$(cat /tmp/vault-keys.json | jq -r .root_token)

vault operator unseal $(cat /tmp/vault-keys.json | jq -r .unseal_keys_b64[0]) || true