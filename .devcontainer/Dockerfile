# docker build -t samgabrail/vault201 .
# docker push samgabrail/vault201

FROM mcr.microsoft.com/devcontainers/universal:2-linux
ARG TERRAFORM_VERSION=1.2.5
ARG VAULT_VERSION=1.12.2
USER root
# Install Terraform and VAULT
RUN apt-get update -y && \
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
mv terraform /usr/bin && \
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
# Install Vault
wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
unzip vault_${VAULT_VERSION}_linux_amd64.zip && \
mv vault /usr/bin && \
rm vault_${VAULT_VERSION}_linux_amd64.zip && \
# Install AWS
pip install --upgrade pip && \
pip install --upgrade awscli
USER codespace