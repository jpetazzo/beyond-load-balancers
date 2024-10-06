#!/bin/bash


kubectl port-forward -n v2 service/bento-api 8888:8080 &

