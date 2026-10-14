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

Use one of these TLS modes. The main LibreNMS chart now manages the application-layer cert-manager resources when TLS automation is enabled.

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
- `ingress.letsEncrypt.createIssuer=false`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.tls.secretName=<certificate-secret-name>`

### 4) Let's Encrypt With ACME-DNS (Existing Secret)

Prerequisites:
- cert-manager installed in the cluster
- Secret with ACME-DNS credentials exists in the namespace expected by the issuer you reference
- Secret contains key `acme-dns-account.json`

Set:
- `ingress.https=true`
- `ingress.letsEncrypt.enabled=true`
- `ingress.letsEncrypt.createIssuer=true`
- `ingress.letsEncrypt.issuerKind=ClusterIssuer` (or `Issuer`)
- `ingress.letsEncrypt.issuerName=letsencrypt-prod`
- `ingress.letsEncrypt.email=admin@example.com`
- `ingress.letsEncrypt.acmeDns.host=auth.example.com`
- `ingress.letsEncrypt.acmeDns.accountSecretName=acme-dns-credentials`
- `ingress.tls.secretName=<certificate-secret-name>`

Manual secret creation example:

```bash
kubectl create secret generic acme-dns-credentials \
  --from-file=acme-dns-account.json=/data/certs/acme-dns-account.json \
  -n cert-manager
```

## Legacy Network Weathermap Plugin

The chart can optionally mount a host-staged Network Weathermap plugin into the LibreNMS container. LibreNMS currently marks this plugin unsupported: it does not work with supported PHP versions, and its pages have no access restriction. Prefer [Custom Maps](https://docs.librenms.org/Extensions/Custom-Map/) for new maps.

If you still need to test an existing installation, place the plugin files (including `map-poller.php` at the plugin directory root) on the Kubernetes host at:

```text
/opt/kubes/storage/<helm-release>/application/plugins/Weathermap/
```

Create that directory before enabling the mount. The path follows `storage.path` and the Helm release name; for a non-default `storage.path`, substitute its configured value. Then set:

```yaml
application:
  weathermap:
    mountPlugin: true
    enable: true
```

Apply the values with your normal `helm upgrade` command. The plugin files are mounted at `/opt/librenms/html/plugins/Weathermap`; configuration and map data continue to use the chart's persistent `/data/weathermap` directory. This only mounts files; it does not download, install, or make the unsupported plugin compatible.

## Remote Poller Services

The chart exposes MySQL (3306), Redis (6379), and RRDcached (42217) through LoadBalancer Services for remote pollers. By default, their source range is restricted to `remotePoller.allowedSourceRanges`. Set `remotePoller.allowFromAnywhere: true` to omit that restriction. This exposes all three ports without a source-IP allowlist; only enable it when network-level controls and service authentication are appropriate.

## Deployment Order

Run these in order to avoid CRD race conditions:

```bash
# 1) Install cert-manager controller + CRDs once
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true

# 2) Install LibreNMS app chart
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
