path "secret/data/aws/awscreds_s3" {
  capabilities = ["list","read"]
}
path "sys/storage/raft/snapshot" {
  capabilities = ["read"]
}