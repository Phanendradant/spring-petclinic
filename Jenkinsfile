pipeline {
    agent any
    environment {
        S3_BUCKET = 'my-unique-s3-bucket-588534b9'
        AWS_REGION = 'us-west-2'
        GIT_REPO = 'https://github.com/Phanendradant/spring-petclinic.git'
        GIT_BRANCH = 'main'
    }
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    retry(3) {
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
        stage('Create S3 Bucket if Not Exists') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id']]) {
                    sh '''
                    aws s3 ls "s3://${S3_BUCKET}" || aws s3 mb "s3://${S3_BUCKET}" --region ${AWS_REGION}
                    '''
                }
            }
        }
        stage('Upload to S3') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id']]) {
                    sh 'aws s3 cp target/*.jar s3://"${S3_BUCKET}"/spring-petclinic.jar'
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                script {
                    sh '''
                    # Download the jar from S3
                    aws s3 cp s3://"${S3_BUCKET}"/spring-petclinic.jar /home/ubuntu/spring-petclinic.jar
                    
                    # Fix file permission issues by using sudo and -S option for password input
                    sudo chmod 777 /home/ubuntu/spring-petclinic.jar
                    
                    # Stop Tomcat, deploy the new jar, and restart Tomcat
                    sudo systemctl stop tomcat9 || true
                    sudo cp /home/ubuntu/spring-petclinic.jar /var/lib/tomcat9/webapps/
                    sudo systemctl start tomcat9
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
