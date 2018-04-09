#!/usr/bin/env bash
REG=${1}
TAG=${2}
NS=${3}
GL_TOKEN=${4}
URL=${4}
export REGISTRY=${REG}
export BUILD_NUMBER=${TAG}
export NAMESPACE=${NS}
export GITLAB_TOKEN=${GL_TOKEN}
export ENV_URL=${URL}
for f in deploy/k8s/*.yml
do
 envsubst < $f > ".generated/$(basename $f)"
done
kubectl apply -f .generated/
