# Security notes

This repository is intentionally environment-agnostic and must not contain real
credentials, private keys, production inventory, internal DNS names, certificates,
VPN configuration, logs, or other environment-specific data.

For CI/CD deployments, provide SSH material using protected CI/CD variables or an
external secrets manager. The example GitLab pipeline expects `SSH_PRIVATE_KEY`
and `SSH_KNOWN_HOSTS` as variables of type **File**.

Before publishing a fork or derivative, review both the working tree and Git
history for secrets and internal infrastructure data.
