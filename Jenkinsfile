pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            steps {
                sh './mvnw clean package'
            }
        }
        stage('Upload to S3') {
            steps {
                withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID'), string(credentialsId: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh 'aws s3 cp target/spring-petclinic-3.3.0-SNAPSHOT.jar s3://my-unique-s3-bucket-588534b9/spring-petclinic.jar'
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID'), string(credentialsId: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                            chmod +w /home/ubuntu/
                            aws s3 cp s3://my-unique-s3-bucket-588534b9/spring-petclinic.jar /home/ubuntu/spring-petclinic.jar
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Deployment Completed'
        }
        failure {
            echo 'Deployment Failed'
        }
    }
}
