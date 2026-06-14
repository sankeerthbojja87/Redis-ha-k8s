# Redis HA on Kubernetes

Hands-on Redis high availability lab on a local KIND cluster.

This repo captures the Redis/Valkey platform practice done on a local Kubernetes
cluster: namespace setup, operator-managed Redis cluster, leader/follower pods,
persistent volumes, metrics services, validation commands, failure drills, and
clean retirement of the lab.

The goal is not only to deploy Redis. The goal is to practice how a platform
engineer thinks about Redis in production:

- Stateful workloads on Kubernetes
- Operator-managed Redis lifecycle
- Persistent volumes and cleanup
- Leader/follower topology
- Service discovery
- Metrics endpoints
- Runbooks for validation, troubleshooting, and teardown

## Topology

Observed lab resources:

```text
Namespace: redis-lab

StatefulSets:
  redis-cluster-leader     3 replicas
  redis-cluster-follower   3 replicas

Services:
  redis-cluster-master
  redis-cluster-leader
  redis-cluster-leader-headless
  redis-cluster-leader-metrics
  redis-cluster-follower
  redis-cluster-follower-headless
  redis-cluster-follower-metrics

PersistentVolumes:
  12 PVCs total
  6 data PVCs
  6 node-conf PVCs

Operator:
  redis-operator

Custom Resource:
  redisclusters redis-cluster
```

## Prerequisites

- macOS or Linux shell
- Docker or Colima
- KIND
- kubectl
- Helm

Check tools:

```bash
docker version
kind version
kubectl version --client
helm version
```

If using Colima:

```bash
colima start
docker context use colima
```

## Create KIND Cluster

```bash
kind create cluster --name redis-lab --config kind/kind-config.yaml
kubectl config use-context kind-redis-lab
kubectl get nodes -o wide
```

## Deploy Redis HA Lab

Create namespace:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl config set-context --current --namespace=redis-lab
```

Install the Redis/Valkey operator.

The exact chart can vary by lab. In the local practice environment the operator
created `redisclusters` resources and leader/follower StatefulSets.

```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
helm repo update
helm install valkey-operator ot-helm/redis-operator -n redis-lab
```

Deploy the Redis cluster custom resource:

```bash
kubectl apply -f k8s/redis-cluster.yaml
```

Deploy a client pod:

```bash
kubectl apply -f k8s/redis-client.yaml
```

Watch rollout:

```bash
kubectl get pods -n redis-lab -w
kubectl get statefulset -n redis-lab
kubectl get svc -n redis-lab
kubectl get pvc -n redis-lab
```

## Validate Cluster

Run:

```bash
./scripts/validate.sh
```

Or run the commands manually:

```bash
kubectl get all -n redis-lab
kubectl get redisclusters -n redis-lab
kubectl get pvc -n redis-lab
kubectl get svc -n redis-lab
kubectl get endpoints -n redis-lab
```

Connect from client:

```bash
kubectl exec -it redis-client -n redis-lab -- sh
```

Inside the pod:

```bash
redis-cli -h redis-cluster-master -p 6379 PING
redis-cli -h redis-cluster-master -p 6379 SET sre redis-ha-k8s
redis-cli -h redis-cluster-master -p 6379 GET sre
```

## Useful Redis Commands

```bash
redis-cli -h redis-cluster-master INFO replication
redis-cli -h redis-cluster-master INFO memory
redis-cli -h redis-cluster-master INFO stats
redis-cli -h redis-cluster-master CLIENT LIST
redis-cli -h redis-cluster-master SLOWLOG GET 10
redis-cli -h redis-cluster-master CONFIG GET maxmemory-policy
```

## Failure Drill

Delete one leader pod and observe recovery:

```bash
kubectl delete pod redis-cluster-leader-0 -n redis-lab
kubectl get pods -n redis-lab -w
```

Validate service after recovery:

```bash
kubectl exec -it redis-client -n redis-lab -- \
  redis-cli -h redis-cluster-master -p 6379 PING
```

Delete one follower pod:

```bash
kubectl delete pod redis-cluster-follower-0 -n redis-lab
kubectl get pods -n redis-lab -w
```

## Backup Practice

Trigger Redis persistence from the master service:

```bash
kubectl exec -it redis-client -n redis-lab -- \
  redis-cli -h redis-cluster-master -p 6379 BGSAVE
```

Find RDB files in pods:

```bash
kubectl exec -it redis-cluster-leader-0 -n redis-lab -- find / -name dump.rdb 2>/dev/null
```

Copy a dump file locally if present:

```bash
kubectl cp redis-lab/redis-cluster-leader-0:/data/dump.rdb ./redis-backup-dump.rdb
```

Path can vary by image/operator. Confirm with `find` first.

## Monitoring Practice

Metrics services were exposed on port `9121`:

```bash
kubectl get svc -n redis-lab | grep metrics
```

Port-forward a metrics service:

```bash
kubectl port-forward svc/redis-cluster-leader-metrics -n redis-lab 9121:9121
```

In another terminal:

```bash
curl localhost:9121/metrics | head
```

Important metrics to understand:

- `redis_up`
- memory usage
- connected clients
- commands processed
- keyspace hits/misses
- evicted keys
- replication state

## Troubleshooting Runbook

Kubernetes:

```bash
kubectl describe pod redis-cluster-leader-0 -n redis-lab
kubectl logs redis-cluster-leader-0 -n redis-lab
kubectl get events -n redis-lab --sort-by=.lastTimestamp
kubectl describe pvc -n redis-lab
kubectl describe svc redis-cluster-master -n redis-lab
```

Redis:

```bash
kubectl exec -it redis-client -n redis-lab -- redis-cli -h redis-cluster-master INFO
kubectl exec -it redis-client -n redis-lab -- redis-cli -h redis-cluster-master INFO replication
kubectl exec -it redis-client -n redis-lab -- redis-cli -h redis-cluster-master INFO memory
kubectl exec -it redis-client -n redis-lab -- redis-cli -h redis-cluster-master SLOWLOG GET 10
```

Common production topics:

- Memory pressure
- Evictions
- Hot keys
- Big keys
- Latency spikes
- Network bandwidth and latency
- Persistence settings
- Failover behavior
- Client connection storms
- Alert noise and actionable thresholds

## Clean Retirement

Run:

```bash
./scripts/cleanup.sh
```

Or run manually:

```bash
kubectl delete redisclusters redis-cluster -n redis-lab
helm uninstall valkey-operator -n redis-lab
kubectl delete pod redis-client -n redis-lab --ignore-not-found
kubectl delete pvc --all -n redis-lab
kubectl delete namespace redis-lab
```

If PVCs are stuck in `Terminating`:

```bash
for pvc in $(kubectl get pvc -n redis-lab -o name); do
  kubectl patch "$pvc" -n redis-lab -p '{"metadata":{"finalizers":null}}' --type=merge
done
```

Final verification:

```bash
kubectl get ns | grep redis
kubectl get all --all-namespaces | grep -i redis
kubectl get pvc --all-namespaces | grep -i redis
kubectl get pv | grep -i redis
helm list --all-namespaces | grep -Ei 'redis|valkey'
```

Note: KIND control-plane pods can include the cluster name, for example
`etcd-redis-lab-control-plane`. Those are not Redis application workloads.

