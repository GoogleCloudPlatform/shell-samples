#!/usr/bin/env groovy
/* Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
          sh 'gcloud config set project ${GOOGLE_CLOUD_PROJECT}'
        }
      }
    }
    stage('Test') {
      steps {
        parallel (
          'zone_failure' : {
            sh './zone_failure/tests/test.sh'
          },
          'biguery-authorization' : {
            sh './bigquery/authorization/test.sh'
          }
        )
      }
    }
  }
  post {
    always {
      sh './zone_failure/tests/post_build.sh'
    }
  }
  environment {
    GOOGLE_CLOUD_PROJECT = 'shell-samples'
    INSTANCE_NAME = 'failure-simulation'
    ZONE = 'us-central1-a'
  }
}
