# Retire Redis Lab Runbook

This runbook captures the cleanup sequence used to retire the local Redis lab.

## Inspect

```bash
kubectl get all -n redis-lab
kubectl get pvc -n redis-lab
kubectl get secret -n redis-lab
kubectl get configmap -n redis-lab
kubectl get svc -n redis-lab
helm list -n redis-lab
```

## Find Custom Resources

```bash
kubectl api-resources | grep -Ei 'redis|valkey'
kubectl get redis --all-namespaces
kubectl get redisclusters --all-namespaces
```

Observed active CR:

```text
NAMESPACE   NAME            CLUSTERSIZE   READYLEADERREPLICAS   READYFOLLOWERREPLICAS
redis-lab   redis-cluster   3             3                     3
```

## Delete Redis Cluster

```bash
kubectl delete redisclusters redis-cluster -n redis-lab
```

Watch cleanup:

```bash
kubectl get all -n redis-lab -w
```

## Uninstall Helm Releases

```bash
helm uninstall redis-cluster -n redis-lab
helm uninstall valkey-operator -n redis-lab
```

Some labs may only have the operator Helm release after the Redis custom
resource is deleted.

## Remove Leftovers

```bash
kubectl delete pod redis-client -n redis-lab --ignore-not-found
kubectl delete statefulset --all -n redis-lab --ignore-not-found
kubectl delete svc --all -n redis-lab --ignore-not-found
kubectl delete pvc --all -n redis-lab
```

If PVCs are stuck in `Terminating`:

```bash
for pvc in $(kubectl get pvc -n redis-lab -o name); do
  kubectl patch "$pvc" -n redis-lab -p '{"metadata":{"finalizers":null}}' --type=merge
done
```

## Delete Namespace

```bash
kubectl delete namespace redis-lab
```

## Verify

```bash
kubectl get ns | grep redis
kubectl get all --all-namespaces | grep -i redis
kubectl get pvc --all-namespaces | grep -i redis
kubectl get pv | grep -i redis
helm list --all-namespaces | grep -Ei 'redis|valkey'
```

KIND control-plane pods can include the cluster name, such as
`etcd-redis-lab-control-plane`. Those are not Redis application workloads.

