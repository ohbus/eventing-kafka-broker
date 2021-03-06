#!/usr/bin/env bash

# Copyright 2020 The Knative Authors
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

# variables used:
# - SKIP_INITIALIZE (default: false) - skip cluster creation

source $(pwd)/vendor/knative.dev/test-infra/scripts/e2e-tests.sh
source $(pwd)/test/data-plane/library.sh
source $(pwd)/test/control-plane/library.sh

SKIP_INITIALIZE=${SKIP_INITIALIZE:-false}

readonly EVENTING_CONFIG="./config"

# Vendored eventing test iamges.
readonly VENDOR_EVENTING_TEST_IMAGES="vendor/knative.dev/eventing/test/test_images/"

export EVENTING_KAFKA_BROKER_ARTIFACT="eventing-kafka-broker.yaml"

function knative_setup() {
  knative_eventing "apply --strict"
  return $?
}

function knative_teardown() {
  knative_eventing "delete --ignore-not-found"
  return $?
}

function knative_eventing() {
  if ! is_release_branch; then
    echo ">> Install Knative Eventing from HEAD"
    pushd .
    cd "${GOPATH}" && mkdir -p src/knative.dev && cd src/knative.dev || fail_test "Failed to set up Eventing"
    git clone https://github.com/knative/eventing
    cd eventing || fail_test "Failed to set up Eventing"
    ko $1 -f "${EVENTING_CONFIG}"
    popd || fail_test "Failed to set up Eventing"
  else
    fail_test "Not ready for a release"
  fi

  # Publish test images.
  echo ">> Publishing test images from eventing"
  # We vendor test image code from eventing, in order to use ko to resolve them into Docker images, the
  # path has to be a GOPATH.
  sed -i 's@knative.dev/eventing/test/test_images@knative.dev/eventing-kafka-broker/vendor/knative.dev/eventing/test/test_images@g' "${VENDOR_EVENTING_TEST_IMAGES}"*/*.yaml
  ./test/upload-test-images.sh ${VENDOR_EVENTING_TEST_IMAGES} e2e || fail_test "Error uploading test images"
  sed -i 's@knative.dev/eventing-kafka-broker/vendor/knative.dev/eventing/test/test_images@knative.dev/eventing/test/test_images@g' "${VENDOR_EVENTING_TEST_IMAGES}"*/*.yaml

  # Enable when we have custom test images
  # ./test/upload-test-images.sh "test/test_images" e2e || fail_test "Error uploading test images"

  ./test/kafka/kafka_setup.sh || fail_test "Failed to set up Kafka cluster"
}

function test_setup() {
  [ -f "${EVENTING_KAFKA_BROKER_ARTIFACT}" ] && rm "${EVENTING_KAFKA_BROKER_ARTIFACT}"

  header "Data plane setup"
  data_plane_setup || fail_test "Failed to set up data plane components"

  header "Control plane setup"
  control_plane_setup || fail_test "Failed to set up control plane components"

  kubectl apply -f "${EVENTING_KAFKA_BROKER_ARTIFACT}" || fail_test "Failed to apply ${EVENTING_KAFKA_BROKER_ARTIFACT}"
}

function test_teardown() {
  kubectl delete -f "${EVENTING_KAFKA_BROKER_ARTIFACT}" || fail_test "Failed to tear down"
}
