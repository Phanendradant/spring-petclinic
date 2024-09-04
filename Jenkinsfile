pipeline {
    agent any
    environment {
        S3_BUCKET = 'my-unique-s3-bucket-bcada9db'
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
                    # Install Tomcat if not already installed
                    sudo yum update -y
                    sudo yum install -y tomcat

                    # Ensure Tomcat directories exist
                    if [ ! -d /var/lib/tomcat/webapps ]; then
                        sudo mkdir -p /var/lib/tomcat/webapps
                    fi

                    # Download the jar file from S3
                    aws s3 cp s3://"${S3_BUCKET}"/spring-petclinic.jar /home/ubuntu/spring-petclinic.jar

                    # Stop Tomcat (ignore if not running)
                    sudo systemctl stop tomcat || true

                    # Copy the jar to the Tomcat webapps directory
                    sudo cp /home/ubuntu/spring-petclinic.jar /var/lib/tomcat/webapps/

                    # Start Tomcat
                    sudo systemctl start tomcat
                    sudo systemctl enable tomcat
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
