FROM openjdk:8-slim-stretch

RUN sed -i -re 's|http://[^/]+/(.*)|http://mirrors.aliyun.com/\1|' /etc/apt/sources.list ;\
    apt-get update ; apt-get install -y --fix-missing procps iputils-ping telnet iproute2 curl redis-tools
    
ARG PKG_NAME

ADD ${PKG_NAME} /app.jar
EXPOSE 8080
VOLUME /tmp
ENTRYPOINT [ \
    "java", "-Djava.security.egd=file:/dev/./urandom", \
    "-XX:+HeapDumpOnOutOfMemoryError", \
    "-XX:HeapDumpPath=/tmp/dump.hprof", \
    "-Xms1024m", \
    "-Xmx2048m", \
    "-jar", "/app.jar" \
]