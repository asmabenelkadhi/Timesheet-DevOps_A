pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test Maven') {
            steps {
                sh 'mvn clean package'
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
                        echo "$REGISTRY_PASSWORD" | docker login localhost:5000 \
                            -u "$REGISTRY_USER" \
                            --password-stdin

                        docker tag backend-app:latest localhost:5000/backend-app:latest

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

                    until docker exec mysql mysqladmin ping -h localhost -uroot -proot --silent; do
                        sleep 2
                    done

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
                    docker logs backend-app
                '''
            }
        }
    }
}
