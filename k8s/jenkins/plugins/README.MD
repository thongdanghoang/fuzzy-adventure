```bash
docker build -t jenkins:lts-jdk21 .
docker tag jenkins:lts-jdk21 harbor.local/library/jenkins:lts-jdk21
docker push harbor.local/library/jenkins:lts-jdk21
```
