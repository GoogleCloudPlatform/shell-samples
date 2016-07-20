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

function GetMetadata() {
  curl -s "$1" -H "Metadata-Flavor: Google"
}

PROJECT_METADATA_URL="http://metadata.google.internal/computeMetadata/v1/project/attributes"
INSTANCE_METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance"
ZONE=$(GetMetadata "$INSTANCE_METADATA_URL/zone" | cut -d '/' -f 4)
INSTANCE_NAME=$(hostname)

# We keep track of the state to make sure failure and recovery is triggered only once.
STATE="healthy"
while true; do
  if [[ "$ZONE" = "$(GetMetadata $PROJECT_METADATA_URL/failed_zone)" ]] && \
     [[ "$INSTANCE_NAME" = *"$(GetMetadata $PROJECT_METADATA_URL/failed_instance_names)"* ]]; then
    if [[ "$STATE" = "healthy" ]]; then
      STATE="failure"
      # Do something to simulate failure here.
      echo "STARTING A FAILURE"
      /etc/init.d/apache2 stop
    fi
  else
    if [[ "$STATE" = "failure" ]] ; then
      STATE="healthy"
      # Do something to recover here.
      echo "RECOVERING FROM FAILURE"
      /etc/init.d/apache2 start
    fi
  fi
  sleep 5
done

