#! /usr/bin/env bash

set -eou pipefail

BRANCH=${1:-""}
if [[ -z "$BRANCH" ]]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

flux-operator suspend -n flux-system rset flux-config

kubectl apply -f <(cat <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  ref:
    name: refs/heads/$BRANCH
EOF
)
