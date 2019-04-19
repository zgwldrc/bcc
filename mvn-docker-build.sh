mvn package
curl -sO $DOCKERFILE_URL
docker login -u $REGISTRY_USER -p $REGISTRY_PASSWD $REGISTRY
docker build -f Dockerfile --build-arg PKG_NAME=clearing-0.0.1-SNAPSHOT.jar -t $REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8} target
docker push $REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:${CI_COMMIT_SHA:0:8} 
