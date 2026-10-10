
pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean compile'
            }
        }

        stage('Tests') {
            steps {
                sh 'mvn -B test'
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn -B org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                            -Dsonar.projectKey=monprojet-springboot \
                            -Dsonar.projectName=MonProjetSpringBoot \
                            -Dsonar.host.url=http://192.168.33.10:9000/ \
                            -Dsonar.token=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('QualityGate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()

                        if (qg.status != 'OK') {
                            error "Quality Gate échoué : ${qg.status}"
                        }

                        echo 'Quality Gate réussi !'
                    }
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn -B -DskipTests package'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t backend-app:latest .'
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry',
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$REGISTRY_PASSWORD" | docker login localhost:5000 \
                            -u "$REGISTRY_USER" \
                            --password-stdin

                        docker tag backend-app:latest \
                            localhost:5000/backend-app:latest

                        docker push localhost:5000/backend-app:latest
                    '''
                }
            }
        }

        stage('MySQL') {
            steps {
                sh '''
                    docker network create timesheet-network || true

                    docker rm -f mysql 2>/dev/null || true

                    docker run -d \
                        --name mysql \
                        --network timesheet-network \
                        -e MYSQL_ROOT_PASSWORD=root \
                        -e MYSQL_DATABASE=timesheet-devops-db \
                        mysql:8.0

                    echo "Waiting for MySQL..."

                    timeout 120 sh -c '
                        until docker exec mysql \
                            mysqladmin ping -h localhost \
                            -uroot -proot --silent; do
                            sleep 2
                        done
                    '

                    echo "MySQL is ready!"
                '''
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                    docker rm -f backend-app 2>/dev/null || true

                    docker pull localhost:5000/backend-app:latest

                    docker run -d \
                        --name backend-app \
                        --network timesheet-network \
                        -p 8082:8082 \
                        localhost:5000/backend-app:latest
                '''
            }
        }

        stage('Verification') {
            steps {
                sh '''
                    echo "=== Docker containers ==="
                    docker ps

                    echo "=== Backend logs ==="
                    docker logs --tail 100 backend-app
                '''
            }
        }
    }
}
