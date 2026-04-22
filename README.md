# LibreNMS-Helm

LibreNMS-Helm deploys LibreNMS on Kubernetes using Helm, including optional supporting services.

## Installation

Run the installer script:

```bash
sudo -i
curl -fsSL https://raw.githubusercontent.com/LoveSkylark/LibreNMS-Installer/main/LibreNMS-Install | sudo bash
```

The script installs:
- Git
- SNMP client
- K3s
- K9s
- Helm
- LibreNMS stack

## Start The Stack

After installation, open a new terminal and run:

```bash
sudo -i
nms start
```

When prompted, set these values first:
- `storage.path`
- `application.host.FQDN`
- `application.host.volumeSize`
- `mariadb.host.volumeSize`
- `mariadb.credentials.rootPassword`
- `mariadb.credentials.user`
- `mariadb.credentials.password`

Save in the editor with `a`, then `Esc`, then `:wq`.

## HTTPS And TLS Options

Use one of these TLS modes.

### 1) Manual TLS Secret

Set:
- `ingress.https=true`
- `ingress.tls.secretName=<secret-name>`

Create the secret:

```bash
kubectl create secret tls <secret-name> \
  --cert=<certificate-file> \
  --key=<key-file> \
  --namespace <namespace>
```

### 2) Manual Wildcard TLS Secret

If you already installed a wildcard certificate secret, set:
- `ingress.https=true`
- `ingress.tls.existingSecretName=<wildcard-secret-name>`

Optional:
- `ingress.redirectToHttps.enabled=true`

When `ingress.tls.existingSecretName` is set, the chart uses that secret and skips the Let's Encrypt issuer flow.

### 3) Let's Encrypt Via Existing Issuer

Prerequisite: cert-manager installed and an `Issuer` or `ClusterIssuer` already created.

Set:
- `ingress.https=true`
- `ingress.letsEncrypt.enabled=true`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.tls.secretName=<certificate-secret-name>`

### 4) Let's Encrypt With Bundled Issuer (Chart Creates It)

Set:
- `ingress.https=true`
- `ingress.letsEncrypt.enabled=true`
- `ingress.letsEncrypt.createIssuer=true`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.letsEncrypt.email=<your-email>`
- `ingress.letsEncrypt.environment=production` or `staging`
- `ingress.letsEncrypt.privateKeySecretName=<acme-account-secret-name>`
- `ingress.tls.secretName=<certificate-secret-name>`

Optional:
- `ingress.redirectToHttps.enabled=true`

### 5) Let's Encrypt With ACME-DNS (Existing Secret)

Prerequisites:
- cert-manager installed in the cluster
- Secret with ACME-DNS credentials already exists in the LibreNMS namespace
- Secret contains key `acme-dns-account.json`

Set:
- `ingress.https=true`
- `ingress.letsEncrypt.enabled=true`
- `ingress.letsEncrypt.createIssuer=true`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.letsEncrypt.email=<your-email>`
- `ingress.letsEncrypt.environment=production` or `staging`
- `ingress.tls.secretName=<certificate-secret-name>`
- `ingress.letsEncrypt.acmeDns.host=<acme-dns-host>`
- `ingress.letsEncrypt.acmeDns.accountSecretName=<existing-secret-name>`

Example:

```yaml
ingress:
  https: true
  className: "traefik"
  redirectToHttps:
    enabled: true
  tls:
    existingSecretName: ""
    secretName: "https-cert"
  letsEncrypt:
    enabled: true
    createIssuer: true
    issuerKind: "ClusterIssuer"
    issuerName: "letsencrypt-prod"
    email: "admin@example.com"
    environment: "production"
    privateKeySecretName: "letsencrypt-account-key"
    server:
      production: "https://acme-v02.api.letsencrypt.org/directory"
      staging: "https://acme-staging-v02.api.letsencrypt.org/directory"
    acmeDns:
      host: "auth.vist.is"
      accountSecretName: "acme-dns-credentials"
```

Manual secret creation example:

```bash
kubectl create secret generic acme-dns-credentials \
  --from-file=acme-dns-account.json=/data/certs/acme-dns-account.json \
  -n librenms
```

## Monitoring During Deploy

Open another shell and run:

```bash
sudo k9s
```

With K9s you can:
- Open a shell in pods
- View logs
- Restart or delete pods during troubleshooting

## Notes

This project is still in active development and improvements are ongoing.
