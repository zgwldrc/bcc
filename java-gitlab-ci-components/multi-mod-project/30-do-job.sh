#!/bin/sh
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/kubectl:v1.11.7
# 说明: 运行一个image为$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8}的任务镜像
# 该任务镜像要求挂载一个名为${APP_NAME}-env的configMap，并从中获取环境变量，从而正确的运行
# Env Var Must
# APP_NAME
# CONTEXT
# KUBECONFIG_CONTENT
# REGISTRY
# REGISTRY_NAMESPACE
# CI_COMMIT_SHA
ENV_CHECK_LIST='
APP_NAME
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

set -e
if grep -q "^${APP_NAME}" build_list;then
  check_env $ENV_CHECK_LIST
  _init_env

  if kubectl get configmaps ${APP_NAME}-env &> /dev/null;then
    kubectl run --rm $APP_NAME --generator=run-pod/v1 --restart=Never --attach \
        --image=$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8} \
        --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"containers\":[{\"envFrom\":[{\"configMapRef\":{\"name\":\"${APP_NAME}-env\"}}],\"image\":\"$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8}\",\"name\":\"$APP_NAME\",\"restartPolicy\":\"Never\"}]}}"
  else
    echo "configmap ${APP_NAME}-env not found."
    exit 1
  fi
fi
