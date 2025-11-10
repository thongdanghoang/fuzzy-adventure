FROM jenkins/inbound-agent:latest-bookworm

USER root

RUN apt-get update && apt-get install -y \
    curl \
    tar \
    gzip \
    unzip \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG JAVA_VERSION=21.0.6_7
ARG JAVA_URL=https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%2B7/OpenJDK21U-jdk_aarch64_linux_hotspot_${JAVA_VERSION}.tar.gz

RUN curl -fsSL ${JAVA_URL} -o /tmp/jdk.tar.gz \
    && mkdir -p /opt/java/openjdk \
    && tar -xzf /tmp/jdk.tar.gz -C /opt/java/openjdk --strip-components=1 \
    && rm /tmp/jdk.tar.gz

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ARG MAVEN_VERSION=3.9.11
ARG MAVEN_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz

RUN curl -fsSL ${MAVEN_URL} -o /tmp/maven.tar.gz \
    && mkdir -p /opt/maven \
    && tar -xzf /tmp/maven.tar.gz -C /opt/maven --strip-components=1 \
    && rm /tmp/maven.tar.gz

ENV M2_HOME=/opt/maven
ENV PATH="${M2_HOME}/bin:${PATH}"

ARG NODE_VERSION=22.21.1
ARG NODE_URL=https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz

RUN curl -fsSL ${NODE_URL} -o /tmp/node.tar.xz \
    && mkdir -p /usr/local/lib/nodejs \
    && tar -xJf /tmp/node.tar.xz -C /usr/local/lib/nodejs --strip-components=1 \
    && rm /tmp/node.tar.xz

ENV PATH="/usr/local/lib/nodejs/bin:${PATH}"

RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo "--- VERIFY ---" && \
    echo "Architech: $(uname -m)" && \
    echo "--- Java Version ---" && \
    java -version && \
    echo "--- Maven Version ---" && \
    mvn -v && \
    echo "--- Node Version ---" && \
    node -v && \
    echo "--- NPM Version ---" && \
    npm -v

USER jenkins