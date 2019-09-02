#!/bin/bash
# YBT前端 h5-web项目master分支的发布脚本
set -e
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

check_env REGISTRY
if [[ "$REGISTRY" =~ .*amazonaws.com$ ]];then
  check_env AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
  REGISTRY_PASSWD=$(aws ecr get-login --no-include-email --region "$AWS_DEFAULT_REGION" | awk '{print $6}')
fi

# 检查必要的环境变量
ENV_CHECK_LIST='
REGISTRY
REGISTRY_USER
REGISTRY_PASSWD
REGISTRY_NAMESPACE
DOCKERFILE_URL
APP_NAME
BUILD_COMMAND
'
check_env $ENV_CHECK_LIST
docker login -u $REGISTRY_USER -p $REGISTRY_PASSWD $REGISTRY
curl -s "$DOCKERFILE_URL" -o Dockerfile

function build() {
    local env=$1
    local build_context=$2
    local image_url=$REGISTRY/$REGISTRY_NAMESPACE/${APP_NAME}:${CI_COMMIT_SHA:0:8}
    docker build -f Dockerfile -t ${image_url} ${build_context}
    docker push ${image_url}
    docker image rm ${image_url}
}

node -v
npm -v
npm install
eval "$BUILD_COMMAND"