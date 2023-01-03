export AWS_ACCESS_KEY_ID=<enter_it_here>
export AWS_SECRET_ACCESS_KEY=<enter_it_here>

## Install Vault with Raft in K8s
kubectl create ns vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault --namespace vault --set server.image.tag=1.12.2,server.ha.enabled=true,server.ha.raft.enabled=true,server.ha.replicas=1 hashicorp/vault
sleep 60

# Expose the Vault service
kubectl -n vault port-forward service/vault 8200:8200 &
# export the vault address
export VAULT_ADDR=http://127.0.0.1:8200

## Initialize and Unseal Vault
kubectl -n vault exec vault-0 -- vault operator init -format=json -key-shares=1 -key-threshold=1 > /tmp/vault-keys.json
export VAULT_TOKEN=$(cat /tmp/vault-keys.json | jq -r .root_token)
vault operator unseal $(cat /tmp/vault-keys.json | jq -r .unseal_keys_b64[0]) || true

# Create the Vault Policy
vault policy write vaultpolicy ./vaultpolicy.hcl

## Vault with K8s Auth
vault auth enable kubernetes
TOKEN_REVIEWER_JWT=$(kubectl -n vault exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
KUBERNETES_PORT_443_TCP_ADDR=$(kubectl -n vault exec vault-0 -- sh -c 'echo $KUBERNETES_PORT_443_TCP_ADDR')
kubectl -n vault exec vault-0 -- cp /var/run/secrets/kubernetes.io/serviceaccount/ca.crt /tmp/ca.crt
kubectl -n vault cp vault-0:/tmp/ca.crt /tmp/ca.crt
vault write auth/kubernetes/config issuer="https://kubernetes.default.svc.cluster.local" token_reviewer_jwt="${TOKEN_REVIEWER_JWT}" kubernetes_host="https://${KUBERNETES_PORT_443_TCP_ADDR}:443" kubernetes_ca_cert=@/tmp/ca.crt
rm /tmp/ca.crt
kubectl -n vault exec vault-0 -- rm /tmp/ca.crt
vault write auth/kubernetes/role/vault \
    bound_service_account_names=vault \
    bound_service_account_namespaces=vault \
    policies=vaultpolicy

## Enable KV v2 and put the AWS creds
vault secrets enable -path=secret -version=2 kv
vault kv put -mount=secret aws/awscreds_s3 AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

## Apply the Vault Backup Cronjob
kubectl apply -n vault -f kubeVaultbackup.yaml
