# Redis Production Notes

## Core Concepts

Redis is an in-memory key-value data store commonly used for:

- Application cache
- Sessions
- Rate limiting
- Counters
- Queues/lightweight coordination
- Leaderboards

## Cache Patterns

- Cache-aside: application reads cache first, then database on miss.
- Write-through: write cache and backing store together.
- Write-behind: write cache first, asynchronously flush to backing store.
- TTL-based expiry: keys expire automatically.
- Explicit invalidation: application removes or updates stale keys.

## Operational Risks

- Hot keys causing uneven load
- Big keys causing latency and memory pressure
- Evictions due to insufficient memory
- Client connection storms
- Slow commands blocking event loop
- Network latency between app and Redis
- Persistence overhead from RDB/AOF
- Failover behavior and client retry storms

## Key Metrics

- Memory used
- Memory fragmentation ratio
- Connected clients
- Commands per second
- Keyspace hits/misses
- Evicted keys
- Expired keys
- Replication lag
- Redis uptime
- Slowlog count
- CPU and network bandwidth

## Linux/Platform Tuning Topics

- File descriptors
- TCP backlog
- Transparent Huge Pages
- `vm.overcommit_memory`
- Swappiness
- CPU throttling
- Kubernetes memory limits
- Pod anti-affinity
- Persistent volume latency

## Kubernetes Production Considerations

- Use StatefulSets for stable pod identity.
- Use PVCs for persistent Redis data when persistence is required.
- Use readiness probes to protect clients from unready pods.
- Use metrics exporter for Prometheus scraping.
- Apply resource requests and limits carefully.
- Spread pods across nodes with anti-affinity.
- Document runbooks for failover, backup, restore, and upgrades.

