// +build e2e

/*
 * Copyright 2020 The Knative Authors
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

package e2e

import (
	"testing"

	"knative.dev/eventing/test/e2e/helpers"

	testbroker "knative.dev/eventing-kafka-broker/test/pkg/broker"
)

func TestEventTransformationForTriggerV1BrokerV1(t *testing.T) {
	runTest(t, "v1", "v1")
}

func TestEventTransformationForTriggerV1Beta1BrokerV1(t *testing.T) {
	runTest(t, "v1", "v1beta1")
}
func TestEventTransformationForTriggerV1Beta1BrokerV1Beta1(t *testing.T) {
	runTest(t, "v1beta1", "v1beta1")
}
func TestEventTransformationForTriggerV1BrokerV1Beta1(t *testing.T) {
	runTest(t, "v1beta1", "v1")
}

func runTest(t *testing.T, brokerVersion string, triggerVersion string) {

	helpers.EventTransformationForTriggerTestHelper(
		t,
		brokerVersion,
		triggerVersion,
		testbroker.Creator,
	)
}
