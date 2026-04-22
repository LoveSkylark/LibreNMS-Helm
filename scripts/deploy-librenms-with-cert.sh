#!/usr/bin/env bash
set -euo pipefail

# Deploy order:
# 1) cert-manager controller + CRDs
# 2) LibreNMS cert resources chart (issuer/certificate)
# 3) LibreNMS app chart

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_CHART_DIR="$ROOT_DIR"
CERT_CHART_DIR="$ROOT_DIR/cert-manager"

NAMESPACE="librenms"
CERT_MANAGER_NAMESPACE="cert-manager"
APP_RELEASE="librenms"
CERT_RELEASE="librenms-cert"
APP_VALUES="/data/lnms-config.yaml"
CERT_VALUES="/data/lnms-cert-config.yaml"
SKIP_CONTROLLER_INSTALL="false"

yaml_value() {
  local file="$1"
  local path="$2"

  awk -v path="$path" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      return value
    }
    BEGIN {
      split(path, keys, ".")
    }
    /^[[:space:]]*#/ { next }
    {
      line = $0
      indent = match(line, /[^ ]/) - 1
      if (indent < 0) {
        next
      }

      content = substr(line, indent + 1)
      if (content ~ /^-/) {
        next
      }
      if (index(content, ":") == 0) {
        next
      }

      key = trim(substr(content, 1, index(content, ":") - 1))
      value = trim(substr(content, index(content, ":") + 1))
      level = int(indent / 2) + 1
      stack[level] = key
      for (i = level + 1; i < 20; i++) {
        delete stack[i]
      }

      matched = 1
      for (i = 1; i <= length(keys); i++) {
        if (!(i in stack) || stack[i] != keys[i]) {
          matched = 0
          break
        }
      }

      if (matched && length(keys) == level && value != "") {
        print value
        exit
      }
    }
  ' "$file"
}

validate_cert_values() {
  local email solver_type acme_dns_host acme_dns_secret

  email="$(yaml_value "$CERT_VALUES" "issuer.email")"
  solver_type="$(yaml_value "$CERT_VALUES" "issuer.solver.type")"
  acme_dns_host="$(yaml_value "$CERT_VALUES" "issuer.solver.acmeDnsHost")"
  acme_dns_secret="$(yaml_value "$CERT_VALUES" "issuer.solver.acmeDnsAccountSecretName")"

  if [[ -z "$email" ]]; then
    echo "Missing issuer.email in $CERT_VALUES" >&2
    exit 1
  fi

  if [[ "$email" =~ (example\.(com|org|net)|your-real-domain|replace-me) ]]; then
    echo "issuer.email in $CERT_VALUES still looks like a placeholder: $email" >&2
    echo "Use a real email address before deploying cert-manager resources." >&2
    exit 1
  fi

  if [[ "${solver_type,,}" == "acmedns" ]]; then
    if [[ -z "$acme_dns_host" || -z "$acme_dns_secret" ]]; then
      echo "issuer.solver.type is acmeDNS, but acmeDnsHost or acmeDnsAccountSecretName is missing in $CERT_VALUES" >&2
      exit 1
    fi
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --app-values <file>        App values file (default: /data/lnms-config.yaml)
  --cert-values <file>       Cert chart values file (default: /data/lnms-cert-config.yaml)
  --namespace <name>         App namespace (default: librenms)
  --cert-manager-ns <name>   cert-manager namespace (default: cert-manager)
  --app-release <name>       App release name (default: librenms)
  --cert-release <name>      Cert release name (default: librenms-cert)
  --skip-controller-install  Skip installing cert-manager controller/CRDs
  -h, --help                 Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-values)
      APP_VALUES="$2"
      shift 2
      ;;
    --cert-values)
      CERT_VALUES="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --cert-manager-ns)
      CERT_MANAGER_NAMESPACE="$2"
      shift 2
      ;;
    --app-release)
      APP_RELEASE="$2"
      shift 2
      ;;
    --cert-release)
      CERT_RELEASE="$2"
      shift 2
      ;;
    --skip-controller-install)
      SKIP_CONTROLLER_INSTALL="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

command -v helm >/dev/null 2>&1 || { echo "helm is required" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }

[[ -f "$APP_VALUES" ]] || { echo "Missing app values file: $APP_VALUES" >&2; exit 1; }
[[ -f "$CERT_VALUES" ]] || { echo "Missing cert values file: $CERT_VALUES" >&2; exit 1; }
[[ -f "$APP_CHART_DIR/Chart.yaml" ]] || { echo "Missing app Chart.yaml at $APP_CHART_DIR" >&2; exit 1; }
[[ -f "$CERT_CHART_DIR/Chart.yaml" ]] || { echo "Missing cert chart at $CERT_CHART_DIR" >&2; exit 1; }

validate_cert_values

if [[ "$SKIP_CONTROLLER_INSTALL" != "true" ]]; then
  echo "[1/4] Installing cert-manager controller and CRDs..."
  helm repo add jetstack https://charts.jetstack.io >/dev/null
  helm repo update >/dev/null

  helm upgrade --install cert-manager jetstack/cert-manager \
    -n "$CERT_MANAGER_NAMESPACE" \
    --create-namespace \
    --set crds.enabled=true \
    --wait

  kubectl rollout status deployment/cert-manager -n "$CERT_MANAGER_NAMESPACE" --timeout=5m
  kubectl rollout status deployment/cert-manager-webhook -n "$CERT_MANAGER_NAMESPACE" --timeout=5m
  kubectl rollout status deployment/cert-manager-cainjector -n "$CERT_MANAGER_NAMESPACE" --timeout=5m
else
  echo "[1/4] Skipping cert-manager controller install"
fi

echo "[2/4] Deploying cert resources chart ($CERT_RELEASE)..."
helm upgrade --install "$CERT_RELEASE" "$CERT_CHART_DIR" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$CERT_VALUES"

echo "[3/4] Updating app dependencies (local charts)..."
helm dependency update "$APP_CHART_DIR"

echo "[4/4] Deploying LibreNMS app chart ($APP_RELEASE)..."
helm upgrade --install "$APP_RELEASE" "$APP_CHART_DIR" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$APP_VALUES"

echo
echo "Validation"
kubectl get crd | grep cert-manager || true
kubectl get clusterissuer || true
kubectl get certificate -n "$NAMESPACE" || true
kubectl get secret https-cert -n "$NAMESPACE" || true

echo
echo "Done."
