# 作者: 夏禹
# 邮箱: zgwldrc@163.com
# 运行环境: zgwldrc/maven-and-docker
# docker run --rm -it zgwldrc/maven-and-docker bash
# 该脚本用于[多模块] Java 项目在gitlab-ci系统中的构建

# -------------------- 必要的环境变量
# REGISTRY
# REGISTRY_USER
# REGISTRY_PASSWD or (AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION)
# REGISTRY_NAMESPACE
# DOCKERFILE_URL
# APP_INFOS_URL
# BUILD_LIST

# -------------------- 可选的环境变量
# MVN_SETTINGS                      : URL of settings.xml
# IMAGE_CLEAN                       : true or false
# BUILD_EXCLUDE_LIST
# DEPLOY_EXCLUDE_LIST

set -e
function include_url_lib() {
  local t="$(mktemp)"
  local url="$1"
  curl -s -o "$t" "$1"
  . "$t"
  rm -f "$t"
}
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
ENV_CHECK_LIST=(
REGISTRY
REGISTRY_USER
REGISTRY_PASSWD
REGISTRY_NAMESPACE
DOCKERFILE_URL
APP_INFOS_URL
BUILD_LIST
)

check_env ${ENV_CHECK_LIST[@]}

docker version
echo "$REGISTRY_USER" "$REGISTRY_PASSWD" "$REGISTRY"
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWD" "$REGISTRY"

function build_app(){
    local app_name=$1
    local package_name=$2
    local build_context=$3

    local image_url=$REGISTRY/$REGISTRY_NAMESPACE/${app_name}:${CI_COMMIT_SHA:0:8}
    docker build -f Dockerfile \
        --build-arg PKG_NAME=${package_name} \
        -t $image_url \
        $build_context
    docker push $image_url
    
    if [ "$IMAGE_CLEAN" == "true" ];then
      docker image rm $image_url
    fi
}
function listTransform(){
  # a,b,c  -->  ^a\s|^b\s|^c\s
  local commaSepratedList="$1"
  commaSepratedList=( ${commaSepratedList//,/ } )
  commaSepratedList=( ${commaSepratedList[@]/#/^} )
  commaSepratedList="${commaSepratedList[@]/%/\\s}"
  commaSepratedList="${commaSepratedList// /|}"
  echo "${commaSepratedList}"
}

APP_INFOS_FILE=/tmp/app-infos.txt
if [ ! -z "$MVN_SETTINGS" ];then
  echo "Found MVN_SETTINGS: $MVN_SETTINGS"
  echo "Downloading..."
  mkdir -p $HOME/.m2/
  curl -s "$MVN_SETTINGS" -o $HOME/.m2/settings.xml && echo "Download Success! " || echo "Download Failed."
fi
curl -s "$APP_INFOS_URL" -o $APP_INFOS_FILE
curl -s "$DOCKERFILE_URL" -o Dockerfile

BUILD_EXCLUDE_LIST=$(listTransform $BUILD_EXCLUDE_LIST)
DEPLOY_EXCLUDE_LIST=$(listTransform $DEPLOY_EXCLUDE_LIST)


if [ "$BUILD_LIST" == "release-all" ] ;then
    grep -Ev "^#|${BUILD_EXCLUDE_LIST:-NOTHINGTOEXCLUDE}" $APP_INFOS_FILE| tee build_list | grep -Ev "${DEPLOY_EXCLUDE_LIST:-NOTHINGTOEXCLUDE}" > deploy_list
    echo -e "\033[32mThis is the build_list:\n"
    awk '{print $1}' build_list
    echo -e "\033[0m"
    echo -e "\n\n\n"
    echo -e "\033[32mThis is the deploy_list:\n"
    awk '{print $1}' deploy_list
    echo -e "\033[0m"
    # 构建所有
    mvn -U clean package
    
    awk '{print $1,$3"-"$4".jar",$2"/target/"}' build_list | while read app_name package_name build_context;do
        build_app $app_name $package_name $build_context
    done
else
    BUILD_LIST=$(listTransform $BUILD_LIST)
    # 根据$BUILD_LIST过滤出需要构建的列表 build_list
    echo -e "\033[32mThis is the build_list:"
    grep -E "$BUILD_LIST" $APP_INFOS_FILE | tee build_list | awk '{print $1}'
    echo -e "\033[0m"

    if [ ! -s build_list ];then
        echo build_list size is 0, nothing to do.
        exit 1
    fi
    
    # 生成部署列表 deploy_list
    echo -e "\033[32mThis is the deploy_list:\n"
    grep -Ev "${DEPLOY_EXCLUDE_LIST:-NOTHINGTOEXCLUDE}" build_list | tee deploy_list | awk '{print $1}'
    echo -e "\033[0m"
     
    # 为mvn命令行构造模块列表参数
    mod_args=$(echo `awk '{print $2}' build_list` | tr ' ' ',')
    mvn clean package -U -pl $mod_args -am
    
    # 调用 build_app 完成 docker build 及 docker push
    awk '{print $1,$3"-"$4".jar",$2"/target/"}' build_list | while read app_name package_name build_context;do
        build_app $app_name $package_name $build_context
    done
    
fi