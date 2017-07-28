#!/usr/bin/env bash
# Copyright 2017 Google Inc.
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

set -e

GOOGLE_CLOUD_PROJECT="$1"
if [[ -z "$GOOGLE_CLOUD_PROJECT" ]] ; then
  echo "Usage: $0 project-id"
  exit 1
fi

# [START get_token]
ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
# [END get_token]

# [START auth_header]
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://www.googleapis.com/bigquery/v2/projects/$GOOGLE_CLOUD_PROJECT/datasets"
# [END auth_header]
