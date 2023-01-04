# Overview

This is a demo of how to backup and restore Vault running in K8s.

## Get Vault Setup

Run the script below to get Vault deployed via Helm as a Raft cluster.

```bash
./start_vault_script.sh
```

## Store the Unseal Keys somewhere safe

```bash
cp /tmp/vault-keys.json keys.json
```

## Insert the AWS Creds in Vault

```bash
export AWS_ACCESS_KEY_ID=<enter_it_here>
export AWS_SECRET_ACCESS_KEY=<enter_it_here>
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$(cat /tmp/vault-keys.json | jq -r .root_token)
vault kv put -mount=secret aws/awscreds_s3 AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
```

## Apply the Vault Backup Cronjob

```bash
kubectl apply -n vault -f kubeVaultbackup.yaml
```

## Check the AWS S3 Console For Backups

Now go to the AWS S3 Console to make sure you're getting backups.

## Destroy the Vault Cluster

Now let's destroy the Vault cluster to simulate a disaster.

```bash
kubectl delete ns vault
```

Also you may need to kill the process that's forwarding the 8200 port. Do that by searching for the process ID and then killing it.

```bash
ps -ef | grep 8200
```

Output:
```
codespa+   79440       1  0 15:39 pts/3    00:00:00 kubectl -n vault port-forward service/vault 8200:8200
```

```bash
kill 79440
```

## Restore Vault from Backup

1. Bring your Vault cluster back online following the circumstances that required you to restore from backup. You will need to reinitialize your Vault cluster and log in with the new root token that was generated during its reinitialization. Note that these will be temporary- the original unseal keys will be needed following restore.

Run the following script to rebuild a new Vault cluster:

```bash
./start_vault_for_recovery.sh
```

2. Copy your Vault Raft Snapshot file onto a Vault cluster member and run the below command, replacing the filename with that of your snapshot file. Note, the -force option is required here since the Auto-unseal or Shamir keys will not be consistent with the snapshot data as you will be restoring a snapshot from a different cluster.

Copy the backup file over:

```bash
aws s3 cp s3://<your_bucket_name>/<your_backup_file.snap> .
```

Restore Vault from backup:

```bash
export VAULT_TOKEN=$(cat /tmp/vault-keys.json | jq -r .root_token)
vault operator raft snapshot restore -force <your_backup_file.snap>
```

3. Once you have restored the Raft snapshot you will need to unseal your Vault cluster again using the following command

```bash
vault operator unseal $(cat keys.json | jq -r .unseal_keys_b64[0]) || true
```


## References

- [Standard Procedure for Restoring a Vault Cluster](https://developer.hashicorp.com/vault/tutorials/standard-procedures/sop-restore)