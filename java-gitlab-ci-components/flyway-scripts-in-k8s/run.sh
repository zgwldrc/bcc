#!/bin/sh
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/kubectl:v1.11.7
# K8S run pod Script Used in Gitlab-CI
# 必要的环境变量
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