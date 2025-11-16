docker tag jenkins:lts-jdk21 harbor.local/library/jenkins:lts-jdk21
docker push harbor.local/library/jenkins:lts-jdk21

```bash
# Start port-forward (keep this running in background)
kubectl port-forward -n harbor deployment/harbor-core 9090:8080 &
```

```bash
docker build -t jenkins:lts-jdk21 .
docker tag jenkins:lts-jdk21 localhost:9090/library/jenkins:lts-jdk21
echo "Harbor12345" | docker login localhost:9090 -u admin --password-stdin
docker push localhost:9090/library/jenkins:lts-jdk21
```
