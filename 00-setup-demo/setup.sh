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
    preload-images aws-demo
fi

p "caching manifests..."
cache-manifests

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

p "create pull request"
create-pull-request

p "initialise project infrastructure"
init-project-infrastructure

echo -e "
Setup is complete!

You can access gitea at the following URL: https://gitea.ocm.dev

Username: ocm-admin
Password: password
"

if [ "$OS" == "Darwin" ];then
    open "https://gitea.ocm.dev/user/login?redirect_to=%2fsoftware-provider/podinfo-component"
else
    xdg-open "https://gitea.ocm.dev/user/login?redirect_to=%2fsoftware-provider/podinfo-component"
fi
