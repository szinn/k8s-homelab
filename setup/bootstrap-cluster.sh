#!/bin/bash
#!/bin/bash
#
. ./common.sh
. ./setup-config.sh

need kubectl
need flux

# Check to make sure it is a recognized cluster
cluster=""
for i in $SETUP_CLUSTERS; do
  if test "$i" == "$1"; then
    cluster=$1
  fi
done
if test -z "$cluster"; then
    echo "Invalid environment $1 - must be one of $SETUP_CLUSTERS"
    exit 1
fi

installFlux() {
  message "Installing fluxv2"
  flux check --pre > /dev/null
  FLUX_PRE=$?
  if [ $FLUX_PRE != 0 ]; then
    echo -e "flux prereqs not met:\n"
    flux check --pre
    exit 1
  fi
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "GITHUB_TOKEN is not set! Check $REPO_ROOT/setup/.env"
    exit 1
  fi

  flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=$GITHUB_REPO \
    --branch $SETUP_GITHUB_BRANCH \
    --private=false \
    --personal \
    --network-policy=false \
    --path=cluster/$cluster

  FLUX_INSTALLED=$?
  if [ $FLUX_INSTALLED != 0 ]; then
    echo -e "flux did not install correctly, aborting!"
    exit 1
  fi
}

message "Bootstrapping cluster $cluster"

. $SETUP_CONFIG_ROOT/env.base
. $SETUP_CONFIG_ROOT/env.$cluster

# Load SOPS key into cluster for decoding
createNamespace flux-system
cat $SOPS_AGE_KEY_FILE | kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=/dev/stdin 2>/dev/null >/dev/null

installFlux
