#!/usr/bin/env bash

# Copyright 2016 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o nounset
set -o errexit
set -o pipefail
set -x

# Check that environment variables are set.
if [[ -z ${PROJECT} ]] ; then
  (>&2 echo "PROJECT environment variable must be set.")
  exit 1
fi

if [[ -z ${INSTANCE_NAME} ]] ; then
  (>&2 echo "INSTANCE_NAME environment variable must be set.")
  exit 1
fi

if [[ -z ${ZONE} ]] ; then
  (>&2 echo "ZONE environment variable must be set.")
  exit 1
fi

# Get this script's directory.
# http://stackoverflow.com/a/246128/101923
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Cleanup after previous runs"
gcloud --project="$PROJECT" compute project-info remove-metadata --keys failed_zone,failed_instance_names

echo "Setup an instance."
gcloud --project="$PROJECT" compute instances create "$INSTANCE_NAME" --zone="$ZONE" --metadata startup-script="sudo apt-get update && sudo apt-get install apache2 -y" --tags=http-server || exit

echo "Geting IP"
IP=$(gcloud --project="$PROJECT" compute instances describe "$INSTANCE_NAME" --zone="$ZONE" | grep "natIP" | tr -s ' ' | cut -d ' ' -f 3)
echo "Got and IP: $IP"

echo "Copy the failure.sh script to VM"
for i in  {1..10} ; do
  gcloud --project="$PROJECT" compute copy-files --zone="$ZONE" "$DIR/../failure.sh" "testuser@$INSTANCE_NAME:~/failure.sh" && rc=$? || rc=$?
  echo "Sleeping 30 seconds"
  sleep 30
  if [[ $rc == 0 ]] ; then
    echo "File copied"
    break
  elif [[ $i != 10 ]] ; then
    echo "Retrying"
  else
    exit 1
  fi
done

echo "Run the failure.sh script in the bg"
for i in  {1..10} ; do
  gcloud --project="$PROJECT" compute ssh --zone="$ZONE" "testuser@$INSTANCE_NAME" --command "sudo bash ~/failure.sh" &
  ssh_pid=$!
  echo "Sleeping 30 seconds"
  sleep 30
  # Check if the background process is still alive.
  if kill -0 $ssh_pid ; then
    echo "Script started"
    break
  elif [[ $i != 10 ]] ; then
    echo "Retrying"
  else
    exit 1
  fi
done

# Wait for IP to serve 200s
until curl -I "$IP" > /dev/null 2> /dev/null
do
  echo "Waiting for Apache to serve"
  sleep 2.
done
echo "Apache is serving - INIT IS DONE"

echo "Enabling failure simulation"
gcloud --project="$PROJECT" compute project-info add-metadata --metadata "failed_zone=${ZONE},failed_instance_names=${INSTANCE_NAME}" || exit

# Wait for IP to top serving 200s
while curl -I "$IP" > /dev/null 2> /dev/null
do
  echo "Waiting for Apache to stop serving"
  sleep 2.
done
echo "Apache stoped serving - ENABLING FAILURE WAS SUCCESSFUL"

# Wait for IP to serve 200s
echo "Reverting from failure simulation"
gcloud --project="$PROJECT" compute project-info remove-metadata --keys failed_zone,failed_instance_names || exit

until curl -I "$IP" > /dev/null 2> /dev/null
do
  echo "Wating for apache to serve again"
  sleep 2.
done
echo "Apache is serving - RECOVERY WAS SUCCESSFUL"

echo "TEST WAS SUCCESSFUL!!!"
