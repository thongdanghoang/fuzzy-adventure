FROM jenkins/jenkins:lts-jdk21

USER root
RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

USER jenkins
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
