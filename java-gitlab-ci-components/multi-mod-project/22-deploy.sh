#!/bin/sh
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/kubectl:v1.11.7
# K8S Deployment Script For Java Multi Module Project Used in Gitlab-CI

# Artifacts Must
# deploy_list

# Env Var Must
# CONTEXT
# KUBECONFIG_CONTENT
# REGISTRY
# REGISTRY_NAMESPACE
# CI_COMMIT_SHA


# 必要的环境变量
ENV_CHECK_LIST='
CONTEXT
KUBECONFIG_CONTENT
REGISTRY
REGISTRY_NAMESPACE
CI_COMMIT_SHA
'

function check_env(){
  local r
  for i do
    eval "r=\${${i}:-undefined}"
    if [ "$r" == "undefined" ];then
      echo "$i is not defined"
      exit 1
    fi
  done
}

function _init_env(){
    mkdir -p $HOME/.kube/
    echo -e "$KUBECONFIG_CONTENT" > $HOME/.kube/config
    kubectl config use-context $CONTEXT
}

check_env $ENV_CHECK_LIST
_init_env
set -e

if [ -n "$BEFORE_DEPLOY_SCRIPT" ];then
    echo "running BEFORE_DEPLOY_SCRIPT: $BEFORE_DEPLOY_SCRIPT"
    curl -s $BEFORE_DEPLOY_SCRIPT | sh
fi

if [ ! -e deploy_list ];then
    echo deploy_list not found 
    exit 1
else
    echo "This is the deploy list:"
    awk '{print $1}' deploy_list
fi

awk '{print $1,$1}' deploy_list | while read app app_instance;do
    kubectl set image deploy $app_instance $app_instance=$REGISTRY/$REGISTRY_NAMESPACE/$app:${CI_COMMIT_SHA:0:8} || true
done