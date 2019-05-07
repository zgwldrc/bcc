#!/bin/sh
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/kubectl:v1.11.7
# 说明: 运行一个image为$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8}的任务镜像
# 该任务镜像要求挂载一个名为${APP_NAME}-env的configMap，并从中获取环境变量，从而正确的运行
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
check_env APP_NAME REGISTRY REGISTRY_NAMESPACE CI_COMMIT_SHA

if kubectl get configmaps ${APP_NAME}-env &> /dev/null;then
    kubectl run --rm $APP_NAME --generator=run-pod/v1 --restart=Never --attach \
        --image=$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8} \
        --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"containers\":[{\"envFrom\":[{\"configMapRef\":{\"name\":\"${APP_NAME}-env\"}}],\"image\":\"$REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8}\",\"name\":\"$APP_NAME\",\"restartPolicy\":\"Never\"}]}}"
else
    echo "configmap ${APP_NAME}-env not found."
    exit 1
fi
