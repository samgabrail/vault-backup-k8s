# docker build -t samgabrail/tekanaid_vault_backup:latest .
# docker push samgabrail/tekanaid_vault_backup:latest
FROM ubuntu:20.04
LABEL maintainer="Sam Gabrail"
ARG VAULT_VERSION="1.12.2"
RUN groupadd -g 999 appuser \
    && useradd -m -r -u 999 -g appuser appuser \
    && apt update -y && apt install -y gnupg wget curl zip unzip \
    && wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && unzip vault_${VAULT_VERSION}_linux_amd64.zip && mv vault /usr/local/bin \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install
USER appuser
WORKDIR /app
COPY backupVault.sh /app/backupVault.sh
CMD [ "./backupVault.sh" ]