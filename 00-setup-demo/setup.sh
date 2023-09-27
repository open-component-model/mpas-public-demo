#!/bin/bash

# demo environment setup
# Version: v1.0.0
# Author: Piaras Hoban <piaras@weave.works>

set -o errexit

OS=$(uname -s)

MODE=0
while true; do
    case $1 in
        --offline-mode)
            MODE=$2
            break;;
        *)
            break;;
    esac
done

cd $(dirname $0)

source ./lib.sh

if [ $MODE -eq 1 ]; then
    p "running in offline mode... please be patient as images are loaded"
fi

p "updating /etc/hosts... will prompt for password if host entries do not exist"
add-hosts

p "running pre-check for tools..."
install-tools

p "running pre-check for charts..."
cache-charts

p "caching images..."
cache-images

p "check complete: all charts downloaded"

p "creating kind cluster"
create-cluster

if [ $MODE -eq 1 ]; then
    p "pre-loading images..."
    preload-images mpas-demo
fi

p "creating tls certs"
configure-tls

p "creating signing keys"
configure-signing-keys

p "deploying gitea"
deploy-gitea

p "deploying ingress"
deploy-ingress

p "create registry certificate secrets"
create-registry-certificate-secrets

p "deploying ocm system signing keys"
setup-ocm-system-signing-keys

p "configuring gitea"
configure-gitea

p "configuring ssh"
configure-ssh

p "deploying mpas controllers"
deploy-mpas-controllers

p "deploy tekton"
deploy-tekton

p "create weave gitops component"
create-weave-gitops-component

p "configure flux repository"
init-repository

p "initialise component repository"
init-component-repository

p "create webhook & receiver"
create-webhook

# It's important that this happens before the project starts to reconcile the repository because
# it can quickly get out of date. The created PR won't be from main but that's fine.
p "create pull request"
create-pull-request

echo -e "
Setup is complete!

You can access gitea at the following URL: https://gitea.ocm.dev

Username: ocm-admin
Password: password

In order to kick off the process of creating the application and the project repository apply the following file:

kubectl apply -f 00-setup-demo/manifests/project.yaml && kubectl wait --for=condition=Ready=true Project/ocm-applications -n mpas-system --timeout=60s
"

if [ "$OS" == "Darwin" ];then
    open "https://gitea.ocm.dev/user/login?redirect_to=%2fsoftware-provider/podinfo-component"
else
    xdg-open "https://gitea.ocm.dev/user/login?redirect_to=%2fsoftware-provider/podinfo-component"
fi
