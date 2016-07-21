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

PROJECT="shell-samples"
INSTANCE_NAME="failure-simulation"
ZONE="us-central1-a"

echo "Cleanup after previous runs"
gcloud --project="$PROJECT" compute project-info remove-metadata --keys failed_zone,failed_instance_names
gcloud --project="$PROJECT" compute instances delete "$INSTANCE_NAME" --zone="$ZONE"

echo "Setup an instance."
gcloud --project="$PROJECT" compute instances create "$INSTANCE_NAME" --zone="$ZONE" --metadata startup-script="sudo apt-get update && sudo apt-get install apache2 -y" --tags=http-server || exit

echo "Geting IP"
IP=$(gcloud --project="$PROJECT" compute instances describe "$INSTANCE_NAME" --zone="$ZONE" | grep "natIP" | tr -s ' ' | cut -d ' ' -f 3)
echo "Got and IP: $IP"

echo "Copy the failure.sh script to VM"
gcloud --project="$PROJECT" compute copy-files --zone="$ZONE" ../failure.sh "$INSTANCE_NAME:~/failure.sh" || exit

echo "Run the failure.sh script in the bg"
gcloud --project="$PROJECT" compute ssh --zone="$ZONE" "$INSTANCE_NAME" --command "sudo bash ~/failure.sh" &

# Wait for IP to serve 200s
until curl -I $IP > /dev/null 2> /dev/null
do
  echo "Waiting for Apache to serve"
  sleep 2.
done
echo "Apache is serving - INIT IS DONE"

echo "Enabling failure simulation"
gcloud --project="$PROJECT" compute project-info add-metadata --metadata failed_zone="$ZONE",failed_instance_names="$INSTANCE_NAME.*" || exit

# Wait for IP to top serving 200s
while curl -I $IP > /dev/null 2> /dev/null
do
  echo "Waiting for Apache to stop serving"
  sleep 2.
done
echo "Apache stoped serving - ENABLING FAILURE WAS SUCCESSFUL"

# Wait for IP to serve 200s
echo "Reverting from failure simulation"
gcloud --project="$PROJECT" compute project-info remove-metadata --keys failed_zone,failed_instance_names || exit

until curl -I $IP > /dev/null 2> /dev/null
do
  echo "Wating for apache to serve again"
  sleep 2.
done
echo "Apache is serving - RECOVERY WAS SUCCESSFUL"

echo "TEST WAS SUCCESSFUL!!!"

echo "deleting the instance"
gcloud --project="$PROJECT" compute instances delete "$INSTANCE_NAME" --zone="$ZONE" -q
