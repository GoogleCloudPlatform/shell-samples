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

# Check that environment variables are set.
if [[ -z ${GOOGLE_CLOUD_PROJECT} ]] ; then
  (>&2 echo "GOOGLE_CLOUD_PROJECT environment variable must be set.")
  exit 1
fi

# Get this script's directory.
# http://stackoverflow.com/a/246128/101923
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OUTPUT="$( "$DIR"/snippets.sh "$GOOGLE_CLOUD_PROJECT" )"

# Check for an expected dataset name.
if [[ "$OUTPUT" != *"shell_samples_test_dataset"* ]] ; then
  echo "Missing shell_samples_test_dataset from snippets output: $OUTPUT"
  exit 1
fi
