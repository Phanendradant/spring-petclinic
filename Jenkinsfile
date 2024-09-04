pipeline {
    agent any
    environment {
        S3_BUCKET = 'your-s3-bucket'
        AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/Phanendradant/spring-petclinic.git'
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

