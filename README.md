# flux-homelab

## Prerequisites


### rook-ceph kubectl plugin
```bash
kubectl krew install rook-ceph
```

### age
```bash
sudo apt install age
```

### sops
```bash
# Download the binary
curl -LO https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64

# Move the binary in to your PATH
sudo mv sops-v3.11.0.linux.amd64 /usr/local/bin/sops

# Make the binary executable
sudo chmod +x /usr/local/bin/sops
```


## Bootstraping flux

1. Install flux-operator

```bash
helm install --create-namespace flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system
```

2. Bootstrap sops key

```bash
cat credentials/age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```

3. Bootstrap flux

```bash
kubectl apply -f flux/base/apps/flux-instance.yml
```

4. Configure kubectl to use vip
```bash
scp -oUserKnownHostsFile=/dev/null \
  -oStrictHostKeyChecking=false \
  -i credentials/id_ed25519 \
  core@10.0.1.1:/etc/rancher/rke2/rke2.yaml credentials/rke2.yaml

sed -i 's/127[.]0[.]0[.]1/10.0.2.1/' credentials/rke2.yaml
export KUBECONFIG=$PWD/credentials/rke2.yaml
kubectl get nodes
```

7. Configure Kubelogin

```bash

unset KUBECONFIG

kubectl config set-cluster k \
  --server=https://10.0.2.1:6443 \
  --embed-certs \
  --certificate-authority=<(openssl s_client -connect 10.0.2.1:6443 -showcerts </dev/null 2>/dev/null | tac | \
    sed -n '/-END CERTIFICATE-/,${p;/-BEGIN CERTIFICATE-/q}' | tac)

kubectl config set-credentials oidc \
    --exec-api-version=client.authentication.k8s.io/v1beta1 \
    --exec-command=kubectl \
    --exec-arg=oidc-login \
    --exec-arg=get-token \
    --exec-arg=--oidc-issuer-url=https://dex.homelab.evilcyborgdrone.com \
    --exec-arg=--oidc-client-id=kube-apiserver \
    --exec-arg=--oidc-extra-scope=email \
    --exec-arg=--oidc-extra-scope=profile \
    --exec-arg=--oidc-extra-scope=groups

kubectl config set-context k --cluster=k --user=oidc
kubectl config use-context k

rm -rf ~/.kube/cache/oidc-login/*

kubectl get nodes
```

## Encrypting Secrets

```bash
sops --age=$(age-keygen -y credentials/age.agekey) \
--encrypt --encrypted-regex '^(data|stringData)$' --in-place path/to/secret/secret.yml
```
