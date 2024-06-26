#!/bin/bash
# libary function vars
# Version: v1.0.0
# Author: Piaras Hoban <piaras@weave.works>

PRIVATE_REPO_NAME=mpas-ocm-applications
SIGNING_KEY_NAME=ocm-signing
MPAS_VERSION="${MPAS_VERSION:-0.8.0}"

SSH_KEY_NAME=ocm-private-demo-key
SSH_KEY_PATH=$HOME/.ssh/$SSH_KEY_NAME

HOSTS=(gitea.ocm.dev gitea-ssh.gitea podinfo.ocm.dev weave-gitops.ocm.dev)

os=$(uname -s)

tools=(helm flux kind jq kubectl ocm mkcert tea git curl docker gzip mpas)

images=(
ghcr.io/open-component-model/podinfo:6.3.5-static
ghcr.io/open-component-model/podinfo:6.3.6-static
ghcr.io/weaveworks/wego-app:v0.24.0
ghcr.io/fluxcd/helm-controller:v0.33.0
ghcr.io/fluxcd/kustomize-controller:v1.0.0-rc.3
ghcr.io/fluxcd/notification-controller:v1.0.0-rc.3
ghcr.io/fluxcd/source-controller:v1.0.0-rc.3
gitea/gitea:1.19.3
registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230312-helm-chart-4.5.2-28-g66a760794
registry.k8s.io/ingress-nginx/controller:v1.7.1
registry.k8s.io/coredns/coredns:v1.10.1
registry.k8s.io/etcd:3.5.7-0
docker.io/kindest/kindnetd:v20230511-dc714da8
registry.k8s.io/kube-apiserver:v1.27.1
registry.k8s.io/kube-controller-manager:v1.27.1
registry.k8s.io/kube-proxy:v1.27.1
registry.k8s.io/kube-scheduler:v1.27.1
docker.io/kindest/local-path-provisioner:v20230511-dc714da8
registry:2
cgr.dev/chainguard/busybox
docker.io/library/alpine:latest
gcr.io/tekton-releases/github.com/tektoncd/dashboard/cmd/dashboard:v0.36.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/controller:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/events:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/git-init:v0.40.2
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/webhook:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/controller:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/eventlistenersink:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/interceptors:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/webhook:v0.24.0
ghcr.io/open-component-model/ocm/ocm.software/ocmcli/ocmcli-image:latest
quay.io/jetstack/cert-manager-cainjector:v1.13.1
quay.io/jetstack/cert-manager-controller:v1.13.1
quay.io/jetstack/cert-manager-webhook:v1.13.1
ghcr.io/external-secrets/external-secrets:v0.9.9
)

preloadimages=(
ghcr.io/open-component-model/podinfo:6.3.5-static
ghcr.io/open-component-model/podinfo:6.3.6-static
ghcr.io/weaveworks/wego-app:v0.24.0
ghcr.io/fluxcd/helm-controller:v1.0.1
ghcr.io/fluxcd/kustomize-controller:v1.3.0
ghcr.io/fluxcd/notification-controller:v1.3.0
ghcr.io/fluxcd/source-controller:v1.3.0
gitea/gitea:1.19.3
registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230312-helm-chart-4.5.2-28-g66a760794
registry.k8s.io/ingress-nginx/controller:v1.7.1
registry.k8s.io/coredns/coredns:v1.10.1
docker.io/kindest/local-path-provisioner:v20230511-dc714da8
registry:2
cgr.dev/chainguard/busybox
docker.io/library/alpine:latest
gcr.io/tekton-releases/github.com/tektoncd/dashboard/cmd/dashboard:v0.36.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/controller:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/events:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/git-init:v0.40.2
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/webhook:v0.48.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/controller:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/eventlistenersink:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/interceptors:v0.24.0
gcr.io/tekton-releases/github.com/tektoncd/triggers/cmd/webhook:v0.24.0
ghcr.io/open-component-model/ocm/ocm.software/ocmcli/ocmcli-image:latest
)

helm_mac_instructions="brew install helm"
flux_mac_instructions="brew install fluxcd/tap/flux"
kind_mac_instructions="brew install kind"
kubectl_mac_instructions="brew install kubectl"
jq_mac_instructions="brew install jq"
git_mac_instructions="brew install git"
curl_mac_instructions="brew install curl"
docker_mac_instructions="brew install docker"
gzip_mac_instructions="brew install gzip"
ocm_mac_instructions="brew install open-component-model/tap/ocm"
mkcert_mac_instructions="brew install mkcert"
tea_mac_instructions="brew tap gitea/tap https://gitea.com/gitea/homebrew-gitea && brew install tea"
mpas_mac_instructions="curl -L https://github.com/open-component-model/MPAS/releases/download/v${MPAS_VERSION}/mpas_${MPAS_VERSION}_darwin_amd64.tar.gz | tar xz && sudo mv mpas /usr/local/bin"
