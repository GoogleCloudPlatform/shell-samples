pipeline {
  agent {
    node {
      label 'python35'
    }
    
  }
  stages {
    stage('zone_failure') {
      steps {
        sh '''gcloud config set project $PROJECT
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS

./zone_failure/tests/test.sh'''
      }
    }
  }
  environment {
    PROJECT = 'shell-samples'
    INSTANCE_NAME = 'failure-simulation'
    ZONE = 'us-central1-a'
  }
}