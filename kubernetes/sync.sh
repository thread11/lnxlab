#!/bin/bash

cd $(dirname -- "$(readlink -f -- "$0")")

remote_hosts=(
  # 192.168.1.100
  # 192.168.1.101
  # 192.168.1.102
120.77.175.66
47.106.166.232
120.79.25.234
)

for remote_host in "${remote_hosts[@]}"; do
  echo "$remote_host"
  scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -p init_kubernetes.sh "${remote_host}":/root/
done
