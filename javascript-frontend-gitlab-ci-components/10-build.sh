#!/bin/bash
# 前端项目dev分支的发布脚本
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
'
check_env $ENV_CHECK_LIST
docker login -u $REGISTRY_USER -p $REGISTRY_PASSWD $REGISTRY
curl -s "$DOCKERFILE_URL" -o Dockerfile

function build() {
    local env=$1
    local bc=$2
    local image_url=$REGISTRY/$REGISTRY_NAMESPACE/${APP_NAME}-${env}:${CI_COMMIT_SHA:0:8}
    docker build -f Dockerfile -t ${image_url} ${bc}
    docker push ${image_url}
    docker image rm ${image_url}
}
node -v
npm -v
npm install
npm run d1
#npm run t1
npm run t2
build d1 d1
#build t1 t1
build t2 t2
