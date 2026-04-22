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

### Update Helm Dependencies

After installation or when using a fresh chart copy, update dependencies:

```bash
cd /data/vault/LibreNMS-Helm
helm dependency update
```

This downloads chart dependencies used by the LibreNMS app chart.

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

Use one of these TLS modes. Cert-manager resources are deployed from the separate chart in `cert-manager/`.

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

### 4) Let's Encrypt With ACME-DNS (Existing Secret)

Prerequisites:
- cert-manager installed in the cluster
- Secret with ACME-DNS credentials exists in cert-manager cluster resource namespace (typically `cert-manager`) when using `ClusterIssuer`
- Secret contains key `acme-dns-account.json`

Set:
- `ingress.https=true`
- `ingress.letsEncrypt.enabled=true`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.tls.secretName=<certificate-secret-name>`

Then deploy the dedicated cert chart with cert-specific values.

Example values for `cert-manager/` chart:

```yaml
enabled: true
issuer:
  create: true
  kind: "ClusterIssuer"
  name: "letsencrypt-prod"
  email: "admin@example.com"
  environment: "production"
  privateKeySecretName: "letsencrypt-account-key"
  solver:
    type: "acmeDNS"
    acmeDnsHost: "auth.vist.is"
    acmeDnsAccountSecretName: "acme-dns-credentials"
certificate:
  create: true
  secretName: "https-cert"
  commonName: "nms.example.com"
  dnsNames:
    - "nms.example.com"
    - "ox.example.com"
    - "smokeping.example.com"
```

Manual secret creation example:

```bash
kubectl create secret generic acme-dns-credentials \
  --from-file=acme-dns-account.json=/data/certs/acme-dns-account.json \
  -n cert-manager
```

## Deployment Order

Run these in order to avoid CRD race conditions:

```bash
# 1) Install cert-manager controller + CRDs once
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true

# 2) Install issuer/certificate resources from the dedicated cert chart
helm upgrade --install librenms-cert ./cert-manager \
  -n librenms -f /data/lnms-cert-config.yaml

# 3) Install LibreNMS app chart
helm upgrade --install librenms . \
  -n librenms -f /data/lnms-config.yaml
```

Validate:

```yaml
kubectl get crd | grep cert-manager
kubectl get clusterissuer
kubectl get certificate -n librenms
kubectl get secret https-cert -n librenms
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
