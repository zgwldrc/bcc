#!/bin/sh
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/kubectl:v1.11.7-helm
# K8S Deployment Script For 前端主平台 Used in Gitlab-CI

# Env Var Must
# APP_NAME: 应用程序名称，等同于Chart名
# 
# CHART_PASSWD: Chart仓库密码
# 
# CHART_REPO: Chart仓库地址 https://repo.chart.com/
# CHART_USER: Chart仓库用户名
# CI_COMMIT_SHA: GITLAB 内置变量, 提交hash
# CONTEXT
# KUBECONFIG_CONTENT
# REGISTRY
# REGISTRY_NAMESPACE
# RELEASE_NAME

# 必要的环境变量
ENV_CHECK_LIST='
APP_NAME
CHART_PASSWD
CHART_REPO
CHART_USER
CI_COMMIT_SHA
CONTEXT
KUBECONFIG_CONTENT
REGISTRY
REGISTRY_NAMESPACE
RELEASE_NAME
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

helm upgrade $RELEASE_NAME $APP_NAME --reuse-values \
  --repo $CHART_REPO --username $CHART_USER --password $CHART_PASSWD \
  --set image.repository=$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME-${CONTEXT} \
  --set image.tag=${CI_COMMIT_SHA:0:8} --wait

#kubectl set image deploy $APP_NAME $APP_NAME=$REGISTRY/$REGISTRY_NAMESPACE/${APP_NAME}-${CONTEXT}:${CI_COMMIT_SHA:0:8} || true
