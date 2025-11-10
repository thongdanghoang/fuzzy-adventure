Chào bạn, câu hỏi này rất hay. Đúng là như vậy.

Vấn đề của bạn là: Mỗi lần pod agent "on-demand" khởi động, nó là một container rỗng. Lệnh `tool` trong `Jenkinsfile` sẽ trigger việc **download và giải nén** JDK, Node.js, Maven... vào trong pod đó. Build xong, pod bị xoá, và lần sau lại lặp lại quy trình download này. Rất lãng phí thời gian.

**Giải pháp tối ưu là "Bake" (Nướng) các tools vào Docker Image.**

Thay vì dùng một image agent chung chung (như `jenkins/inbound-agent`) và cài tools lúc chạy, bạn sẽ tự build một image agent **đã cài sẵn** JDK, Node, và Maven.

-----

### 🚀 Bước 1: Tạo một `Dockerfile` cho agent

Bạn tạo một file tên là `Dockerfile` (không có đuôi) với nội dung sau. File này sẽ lấy image agent cơ bản và cài thêm các tool bạn cần.

```dockerfile
# Bắt đầu từ image agent có sẵn JDK 17 (hoặc JDK 11, 21 tuỳ bạn)
FROM jenkins/inbound-agent:latest-jdk17

# Chuyển sang user 'root' để có quyền cài đặt
USER root

# --- Cài Maven (Ví dụ: phiên bản 3.9.8) ---
# (Jenkins tool của bạn ghi 3.9.11, có thể là tên tuỳ chỉnh, 
# ở đây tôi dùng bản 3.9.8 chính thức)
ARG MVN_VERSION=3.9.8
RUN apt-get update && apt-get install -y wget \
    && wget https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz \
    && tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MVN_VERSION}/bin/mvn /usr/bin/mvn \
    && rm apache-maven-${MVN_VERSION}-bin.tar.gz \
    && apt-get-purge -y wget

# --- Cài Node.js (Ví dụ: phiên bản 22.x) ---
# (Lấy bản LTS gần nhất với yêu cầu 22.21.1 của bạn)
ARG NODE_VERSION=22.2.0 
RUN wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz \
    && tar -xvf node-v${NODE_VERSION}-linux-x64.tar.xz -C /usr/local --strip-components=1 \
    && rm node-v${NODE_VERSION}-linux-x64.tar.xz

# --- Dọn dẹp ---
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# (Quan trọng) Chuyển về user 'jenkins' để chạy agent
USER jenkins
```

-----

### 📦 Bước 2: Build và Push Image lên Harbor

Vì bạn đã có Harbor, bạn sẽ build image này và đẩy nó lên registry nội bộ của mình.

1.  **Login vào Harbor:** (Giả sử Harbor của bạn là `harbor.local.thongdanghoang.id.vn`)

    ```bash
    docker login harbor.local.thongdanghoang.id.vn
    ```

2.  **Build và Push:** (Giả sử bạn có project tên `ci-tools` trên Harbor)

    ```bash
    # Build image
    docker build -t harbor.local.thongdanghoang.id.vn/ci-tools/jenkins-agent-maven-node:latest .

    # Đẩy image lên Harbor
    docker push harbor.local.thongdanghoang.id.vn/ci-tools/jenkins-agent-maven-node:latest
    ```

-----

### 🛠️ Bước 3: Cập nhật Cấu hình Jenkins

#### 1\. Cập nhật Pod Template

Bạn cần vào **Manage Jenkins** -\> **Configure System** -\> **Cloud** -\> **Kubernetes**, tìm đến **Pod Templates** của bạn.

Thay vì dùng image `jenkins/inbound-agent`, bạn đổi `Container Template` để trỏ đến image mới trên Harbor:

* **Image:** `harbor.local.thongdanghoang.id.vn/ci-tools/jenkins-agent-maven-node:latest`

#### 2\. Cập nhật `Jenkinsfile`

Bây giờ `Jenkinsfile` của bạn sẽ trở nên **đơn giản hơn rất nhiều**. Bạn không cần `tool` nữa, vì các lệnh `mvn`, `node` đã có sẵn trong `PATH` của image.

```groovy
node {
    // Không cần 'def mvn = tool ...'
    // Không cần 'def nodeHome = tool ...'
    
    def sonarProjectKey = 'thongdanghoang_fkr2_58e81e54-366d-4ec3-a1fb-9577a8ae88b6'
    def sonarProjectName = 'fkr2'

    // Không cần 'withEnv' cho PATH nữa (nhưng vẫn cần cho SONAR_USER_HOME)
    withEnv(["SONAR_USER_HOME=${env.WORKSPACE}/.sonar"]) {
        stage('SCM') {
            checkout scm
            // Các lệnh này giờ chạy trực tiếp!
            sh 'node -v && npm -v'
        }

        stage('Build, Test & Sonar Analysis') {
            
            def rtServer = Artifactory.server('artifactory-oss')
            def rtMaven = Artifactory.newMavenBuild()
            
            // Chỉ cần gọi tên 'maven-3.9.11' (nếu bạn vẫn giữ tên này trong Global Tools)
            // HOẶC, nếu không dùng plugin Artifactory, bạn gọi thẳng:
            // sh "mvn clean verify ..."
            
            // Nếu dùng Artifactory plugin, bạn vẫn cần khai báo tool
            // nhưng Jenkins sẽ bỏ qua bước cài đặt vì nó đã có sẵn.
            // TỐT NHẤT: Bỏ rtMaven.tool đi và dùng sh
            
            rtMaven.resolver releaseRepo: 'maven-virtual', snapshotRepo: 'maven-virtual', server: rtServer
            
            withSonarQubeEnv() {
                def sonarArgs = "-Dsonar.projectKey=${sonarProjectKey} -Dsonar.projectName='${sonarProjectName}'"
                
                // CÁCH 1: Vẫn dùng Artifactory plugin (nó sẽ tìm 'mvn' trong PATH)
                // Bỏ dòng rtMaven.tool đi
                rtMaven.run pom: 'pom.xml', goals: "clean verify -B -Pcoverage sonar:sonar ${sonarArgs}"

                // CÁCH 2 (Đơn giản hơn):
                // Dùng file settings.xml để trỏ về Artifactory và gọi sh
                // configFileProvider([configFile(id: 'maven-settings-artifactory', variable: 'MAVEN_SETTINGS')]) {
                //     sh "mvn -s $MAVEN_SETTINGS clean verify -B -Pcoverage sonar:sonar ${sonarArgs}"
                // }
            }
            
            junit '**/target/surefire-reports/*.xml'
        }
        
        stage('Quality Gate') {
            // ... (như cũ) ...
        }
    }
}
```

**Tóm lại:** Bằng cách "nướng" (bake) tools vào image, pod của bạn khởi động gần như **ngay lập tức** và sẵn sàng build, thay vì chờ 30-60 giây (hoặc lâu hơn) để download và giải nén tools.