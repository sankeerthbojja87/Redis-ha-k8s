#!/usr/bin/env bash
set -euo pipefail

echo "Deleting RedisCluster custom resource..."
kubectl delete redisclusters redis-cluster -n redis-lab --ignore-not-found

echo "Uninstalling operator Helm release..."
helm uninstall valkey-operator -n redis-lab || true

echo "Deleting client pod..."
kubectl delete pod redis-client -n redis-lab --ignore-not-found

echo "Deleting services/statefulsets if any remain..."
kubectl delete statefulset --all -n redis-lab --ignore-not-found
kubectl delete svc --all -n redis-lab --ignore-not-found

echo "Deleting PVCs..."
kubectl delete pvc --all -n redis-lab --ignore-not-found

echo "If PVCs are stuck, remove finalizers with:"
echo "for pvc in \$(kubectl get pvc -n redis-lab -o name); do kubectl patch \"\$pvc\" -n redis-lab -p '{\"metadata\":{\"finalizers\":null}}' --type=merge; done"

echo "Deleting namespace..."
kubectl delete namespace redis-lab --ignore-not-found

