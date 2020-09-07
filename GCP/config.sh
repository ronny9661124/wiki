#!/bin/bash

# ALL
export PRODUCT_ID="a02"
export SERVER_ID="nginx-cluster"
export PROJECT_ID="west-edge-tech-service-inc"
export ZONE="asia-southeast1-c"
export NETWORK="vpc-sg"

# VM
export VM_SIZE=2
export VM_TEMPLATE_NAME="vm-template-${PRODUCT_ID}-${SERVER_ID}"
export VM_DISK_NAME="vm-diskname-${PRODUCT_ID}-${SERVER_ID}"
export VM_GROUP_NAME="vm-group-${PRODUCT_ID}-${SERVER_ID}"
export SOURCE_MACHINE_IMAGE="image-a01-nginxcluster-v20200828164534"
export VM_GROUP_NAME="vm-group-${PRODUCT_ID}-${SERVER_ID}"
export VM_LIST="a01-nginxcluster-20200828164936"
# LB
export LB_IP_NAME="lb-ip-${PRODUCT_ID}-${SERVER_ID}"
export LB_HEALTH_CHECKS_NAME="http-basic-check"
export LB_BACKEND_NAME="lb-backend-${PRODUCT_ID}-${SERVER_ID}"
export LB_WEB_MAP_NAME="lb-webmap-${PRODUCT_ID}-${SERVER_ID}"
export LB_PROXY_NAME="lb-proxy-${PRODUCT_ID}-${SERVER_ID}"
export LB_FWD_RULE="lb-proxy-${PRODUCT_ID}-${SERVER_ID}"