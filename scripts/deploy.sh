#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f k8s/namespace.yaml
kubectl config set-context --current --namespace=redis-lab

helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
helm repo update
helm upgrade --install valkey-operator ot-helm/redis-operator -n redis-lab

kubectl apply -f k8s/redis-cluster.yaml
kubectl apply -f k8s/redis-client.yaml

echo "Redis HA lab deployment started."
echo "Watch rollout with: kubectl get pods -n redis-lab -w"

