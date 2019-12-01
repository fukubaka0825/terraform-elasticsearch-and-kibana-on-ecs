#!/bin/bash
# Set the ECS agent configuration options
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=15m
ECS_IMAGE_CLEANUP_INTERVAL=10m
EOF
sysctl -w vm.max_map_count=262144
mkdir -p /usr/share/elasticsearch/data/
chown -R 1000.1000 /usr/share/elasticsearch/data/