#!/bin/bash -e
#!/usr/bin/env bash

echo "Build pulp/pulpcore images"
cd $GITHUB_WORKSPACE/containers/
cp $GITHUB_WORKSPACE/.ci/ansible/vars.yaml vars/vars.yaml
pip install ansible
ansible-playbook -v build.yaml
cd $GITHUB_WORKSPACE

echo "Test pulp/pulpcore images"
sudo -E ./up.sh
.ci/scripts/pulp-operator-check-and-wait.sh
.ci/scripts/pulp_file-tests.sh

podman images

echo "Deploy pulp-operator"
sudo -E PODMAN_OR_DOCKER=docker $GITHUB_WORKSPACE/.ci/scripts/quay-push.sh

echo "Deploy pulp latest"
sudo -E QUAY_REPO_NAME=pulp $GITHUB_WORKSPACE/.ci/scripts/quay-push.sh

echo "Deploy pulpcore latest"
sudo -E QUAY_REPO_NAME=pulpcore $GITHUB_WORKSPACE/.ci/scripts/quay-push.sh

echo "Building the bundle"
make bundle-build BUNDLE_IMG="quay.io/pulp/pulp-operator-bundle:0.0.1"
sudo -E PODMAN_OR_DOCKER=docker QUAY_REPO_NAME="pulp-operator-bundle" QUAY_IMAGE_TAG="0.0.1" $GITHUB_WORKSPACE/.ci/scripts/quay-push.sh
