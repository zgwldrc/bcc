#!/bin/bash
# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/maven-and-docker
# docker run --rm -it zgwldrc/maven-and-docker sh
# 该脚本用于crush项目在gitlab-ci系统中的构建
##################### ENV ARG MUST
# REGISTRY
# REGISTRY_NAMESPACE
# REGISTRY_USER
# REGISTRY_PASSWD or (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION)
# APP_NAME
# DOCKERFILE_URL

##################### ENV ARG OPTIONAL
# MVN_SETTINGS 
# IMAGE_CLEAN bool

set -x
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

if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_SECRET_ACCESS_KEY" && ! -z "$AWS_DEFAULT_REGION" ]] ;then
  REGISTRY_PASSWD=$(aws ecr get-login --no-include-email --region "$AWS_DEFAULT_REGION" | awk '{print $6}')
fi

# 检查必要的环境变量
ENV_CHECK_LIST='
REGISTRY
REGISTRY_USER
REGISTRY_PASSWD
REGISTRY_NAMESPACE
APP_NAME
DOCKERFILE_URL
CI_COMMIT_SHA
'
check_env $ENV_CHECK_LIST
docker version
# get docker credential
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWD" "$REGISTRY"

if [ ! -z "$MVN_SETTINGS" ];then
  echo "Found MVN_SETTINGS: $MVN_SETTINGS"
  echo "Downloading..."
  mkdir -p $HOME/.m2/
  curl -s "$MVN_SETTINGS" -o $HOME/.m2/settings.xml && echo "Download Success! " || echo "Download Failed."
fi

# get build context 
BUILD_CONTEXT=$(mktemp -d)
# get Dockerfile
curl -H "Cache-Control: no-cache" -so $BUILD_CONTEXT/Dockerfile $DOCKERFILE_URL
# get docker image url
IMAGE_URL=${REGISTRY}/$REGISTRY_NAMESPACE/${APP_NAME}:${CI_COMMIT_SHA:0:8}


# MVN PACKAGE
mvn package
PKG_ABS_PATH=`mvn -q exec:exec -Dexec.executable='echo' -Dexec.args='${project.build.directory}/${project.artifactId}-${project.version}.${project.packaging}'`

mv $PKG_ABS_PATH $BUILD_CONTEXT/
PKG_NAME=`basename ${PKG_ABS_PATH}`
# Docker Build
docker build --build-arg PKG_NAME=${PKG_NAME} -t $IMAGE_URL $BUILD_CONTEXT/
docker push $IMAGE_URL

# clean
if [ "$IMAGE_CLEAN" == "true" ];then
      docker image rm $IMAGE_URL
fi