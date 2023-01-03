#!/usr/bin/bash
echo "✅ Kubectl and Helm installed successfully"

sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
brew install derailed/k9s/k9s

echo "✅ kubectx, kubens, fzf, and k9s installed successfully"
sudo apt-get update -y
sudo apt-get install fzf -y

alias k="kubectl"
alias kga="kubectl get all"
alias kgn="kubectl get all --all-namespaces"
alias kdel="kubectl delete"
alias kd="kubectl describe"
alias kg="kubectl get"

echo 'alias k="kubectl"' >> /home/$USER/.bashrc
echo 'alias kga="kubectl get all"' >> /home/$USER/.bashrc
echo 'alias kgn="kubectl get all --all-namespaces"' >> /home/$USER/.bashrc
echo 'alias kdel="kubectl delete"' >> /home/$USER/.bashrc
echo 'alias kd="kubectl describe"' >> /home/$USER/.bashrc
echo 'alias kg="kubectl get"' >> /home/$USER/.bashrc

echo "✅ The following aliases were added:"
echo "alias k=kubectl"
echo "alias kga=kubectl get all"
echo "alias kgn=kubectl get all --all-namespaces"
echo "alias kdel=kubectl delete"
echo "alias kd=kubectl describe"
echo "alias kg=kubectl get"
source /home/$USER/.bashrc

## Install Vault with Raft in K8s
kubectl create ns vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault --namespace vault --set server.image.tag=1.12.2,server.ha.enabled=true,server.ha.raft.enabled=true,server.ha.replicas=1 hashicorp/vault
echo "✅ Vault installed in K8s via Helm"
sleep 90

## Initialize and Unseal Vault
kubectl -n vault exec vault-0 -- vault operator init -format=json -key-shares=1 -key-threshold=1 >> /tmp/vault-keys.json
export VAULT_TOKEN=$(cat /tmp/vault-keys.json | jq -r .root_token)
vault operator unseal $(cat /tmp/vault-keys.json | jq -r .unseal_keys_b64[0])
echo "✅ Vault initialized and unsealed"

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
    policies=vault


kubectl apply -n vault -f ../kubeVaultbackup.yaml

source ~/.bashrc 