#!/bin/bash
##################### ENV ARG MUST
# REGISTRY
# REGISTRY_USER
# REGISTRY_PASSWD
# REGISTRY_NAMESPACE
# IMAGE_NAME
# DOCKERFILE_URL
# CI_COMMIT_SHA
##################### ENV ARG OPTIONAL
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

# 检查必要的环境变量
ENV_CHECK_LIST='
REGISTRY
REGISTRY_USER
REGISTRY_PASSWD
REGISTRY_NAMESPACE
IMAGE_NAME
DOCKERFILE_URL
CI_COMMIT_SHA
'
check_env $ENV_CHECK_LIST
docker version
# get docker credential
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWD" "$REGISTRY"
# get build context 
BUILD_CONTEXT=$(mktemp)
# get Dockerfile
curl -so $BUILD_CONTEXT/Dockerfile $DOCKERFILE_URL
# get docker image url
IMAGE_URL=${REGISTRY}/$REGISTRY_NAMESPACE/${IMAGE_NAME}:${CI_COMMIT_SHA:0:8}


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




