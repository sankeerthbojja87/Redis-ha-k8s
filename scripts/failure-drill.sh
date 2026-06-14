#!/usr/bin/env bash
set -euo pipefail

echo "Deleting one Redis leader pod to practice StatefulSet recovery..."
kubectl delete pod redis-cluster-leader-0 -n redis-lab

echo
echo "Watch recovery:"
echo "kubectl get pods -n redis-lab -w"
echo
echo "After pod is Running, validate:"
echo "kubectl exec -it redis-client -n redis-lab -- redis-cli -h redis-cluster-master -p 6379 PING"

