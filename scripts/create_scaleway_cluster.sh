#!/bin/sh
NAME=llmplanet-$(base64 /dev/urandom | tr A-Z a-z | tr -d +/ | head -c5)
scw k8s cluster create name=$NAME \
  pools.0.name=cpu-8c-16g pools.0.size=2 pools.0.node-type=POP2-HC-8C-16G pools.0.autoscaling=true pools.0.max-size=100
while scw k8s cluster list name=$NAME; do
  echo ""
  echo "Once the cluster shows up as 'ready', you can stop this command, and run:"
  echo "scw k8s kubeconfig install <clusterid>"
  echo "To delete the cluster:"
  echo "scw k8s cluster delete <clusterid>"
  echo ""
  sleep 10
done
