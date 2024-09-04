pipeline {
    agent any
    environment {
        S3_BUCKET = 'your-s3-bucket'
        AWS_REGION = 'us-east-1'
        GIT_REPO = 'https://github.com/Phanendradant/spring-petclinic.git'
        GIT_BRANCH = 'main' // Specify the branch you want to pull from
    }
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    retry(3) { // Retry up to 3 times in case of intermittent errors
                        checkout([$class: 'GitSCM', branches: [[name: "${GIT_BRANCH}"]],
                        userRemoteConfigs: [[url: "${GIT_REPO}"]]])
                    }
                }
            }
        }
        stage('Build') {
            steps {
                sh './mvnw clean package'
            }
        }
        stage('Upload to S3') {
            steps {
                sh 'aws s3 cp target/*.war s3://${S3_BUCKET}/spring-petclinic.war'
            }
        }
        stage('Deploy to EC2') {
            steps {
                script {
                    sh '''
                    aws s3 cp s3://${S3_BUCKET}/spring-petclinic.war /home/ec2-user/spring-petclinic.war
                    sudo systemctl stop tomcat
                    sudo cp /home/ec2-user/spring-petclinic.war /var/lib/tomcat/webapps/
                    sudo systemctl start tomcat
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Deployment Successful'
        }
        failure {
            echo 'Deployment Failed'
        }
    }
}
