#!/bin/bash

  set -ex

  API_KEY='b66a6fa942ed721e'
  INTEGRATIONS_API_URL='https://api.qualiti-dev.com'
  PROJECT_ID='3'
  CLIENT_ID='8e9b4a432a222d190db4adb77c35c647'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-f7dl5n54uwn.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='916887f09e09ae4d9333c18633ed4203fcdd43f2cb43dfdc871a17c0ccdafb689d1002de3982cd470f637d7b0c0abc92c2fb4770b26bc10199f1fce59eee903dc9e46173394251ef7e2a3702e8388e9f32eaae5b2c3f9fb61217e100acecd08cde6b048b1f222e1b2d2a46ba505d3fedbff8dc93a5ff5fef984c7d2a7643d45ffe12961a512b4cbcd7d02d6b75a3450714d9a57f8bdacf2c8c0a3767b82ad0751461cd43947a17aadf1e9667d64fd89c51188af3c76b90ffb29e1ced85e3ed7c9776f1b5926b2e288312317c8bd49270040d7c28f8e3f0ffc1af9c21d96413993aff44f8cf076928a83ea3ab8639686c7eafad8ad8f8fbabadd7918e679417bfffcb175b608f330f848f6edc278b69b6|195d633a460c137c1bfddff4b80f7078|a280e966202346746ccd6fbe8eb88c50'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
