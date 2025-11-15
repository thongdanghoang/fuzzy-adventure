```bash
docker build -t jenkins:lts-jdk21 .
docker tag jenkins:lts-jdk21 harbor.orb.local/library/jenkins:lts-jdk21
docker push harbor.orb.local/library/jenkins:lts-jdk21
```
