#!/usr/bin/env bash
set -euo pipefail

kubectl get ns redis-lab
kubectl get all -n redis-lab
kubectl get redisclusters -n redis-lab
kubectl get pvc -n redis-lab
kubectl get svc -n redis-lab

echo
echo "Testing Redis master service from redis-client..."
kubectl exec -n redis-lab redis-client -- redis-cli -h redis-cluster-master -p 6379 PING
kubectl exec -n redis-lab redis-client -- redis-cli -h redis-cluster-master -p 6379 SET sre redis-ha-k8s
kubectl exec -n redis-lab redis-client -- redis-cli -h redis-cluster-master -p 6379 GET sre

