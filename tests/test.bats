#!/usr/bin/env bats

load 'test-helper'

@test "fetch tests/fixtures/example-chart/values.yaml" {
    run helm_init "$HELM_HOME"
    url="git+${FIXTURES_GIT_REPO}@tests/fixtures/example-chart-symlink/index.yaml?ref=${FIXTURES_GIT_REF}"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" 2>/dev/null > "$HELM_GIT_OUTPUT/values.yaml"
    [ $? = 0 ]
    run stat "$HELM_GIT_OUTPUT/index.yaml"
    [ $status = 0 ]
}
