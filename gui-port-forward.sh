#!/bin/bash


kubectl port-forward -n promstack service/promstack-grafana 8080:80 &
kubectl port-forward -n promstack service/prometheus-operated 8081:9090 &
kubectl port-forward -n default service/mq 8082:15672 &
