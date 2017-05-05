pipeline {
  agent {
    node {
      label 'python35'
    }
    
  }
  stages {
    stage('Setup') {
      steps {
        withCredentials([file(credentialsId: 'e93a361a-fd14-4b05-bd34-b3d50c51d1c7', variable: 'SERVICE_ACCOUNT')]) {
          sh 'gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT"'
          sh "gcloud config set project ${PROJECT}"
        }
      }
    }
    stage('zone_failure') {
      steps {
        sh './zone_failure/tests/test.sh'
      }
    }
  }
  environment {
    PROJECT = 'shell-samples'
    INSTANCE_NAME = 'failure-simulation'
    ZONE = 'us-central1-a'
  }
}
