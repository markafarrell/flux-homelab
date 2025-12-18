#! /usr/bin/env bash

set -eou pipefail

flux-operator resume -n flux-system rset flux-config
