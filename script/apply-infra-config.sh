#!/usr/bin/env bash
set -e

# ==============================================================================
# Script: script/apply-infra-config.sh
# Description: Synchronize environment variables from .env to Pulumi Stack Config
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  .env file not found at ${ENV_FILE}"
  exit 1
fi

echo "🔄 Loading environment variables from .env..."
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export PATH="$HOME/.pulumi/bin:$PATH"
export PULUMI_CONFIG_PASSPHRASE="${PULUMI_CONFIG_PASSPHRASE:-modern-rails-passphrase}"

cd "${PROJECT_ROOT}/infra"

# Ensure Pulumi local backend login and stack selection
pulumi login --local >/dev/null 2>&1
PULUMI_STACK="${PULUMI_STACK:-dev}"
pulumi stack select "$PULUMI_STACK" --create >/dev/null 2>&1

echo "📦 Syncing configuration to Pulumi stack [${PULUMI_STACK}]..."

# GCP Configuration
if [ -n "$GCP_PROJECT" ]; then
  pulumi config set gcp:project "$GCP_PROJECT"
  echo "  ✓ gcp:project = ${GCP_PROJECT}"
fi

if [ -n "$GCP_REGION" ]; then
  pulumi config set gcp:region "$GCP_REGION"
  echo "  ✓ gcp:region = ${GCP_REGION}"
fi

if [ -n "$GCP_ZONE" ]; then
  pulumi config set gcp:zone "$GCP_ZONE"
  echo "  ✓ gcp:zone = ${GCP_ZONE}"
fi

# Cloudflare Configuration
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  pulumi config set --secret cloudflare:apiToken "$CLOUDFLARE_API_TOKEN"
  echo "  ✓ cloudflare:apiToken (encrypted secret)"
fi

if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  pulumi config set modern-rails-infra:cloudflareZoneId "$CLOUDFLARE_ZONE_ID"
  echo "  ✓ modern-rails-infra:cloudflareZoneId = ${CLOUDFLARE_ZONE_ID}"
fi

if [ -n "$CLOUDFLARE_DOMAIN" ]; then
  pulumi config set modern-rails-infra:domain "$CLOUDFLARE_DOMAIN"
  echo "  ✓ modern-rails-infra:domain = ${CLOUDFLARE_DOMAIN}"
fi

if [ -n "$DOMAIN" ]; then
  pulumi config set modern-rails-infra:domain "$DOMAIN"
  echo "  ✓ modern-rails-infra:domain = ${DOMAIN}"
fi

echo ""
echo "🎉 Pulumi configuration successfully updated!"
echo "👉 You can now run: cd infra && pulumi preview (or pulumi up)"
